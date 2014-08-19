require 'openssl'
require 'stringio'
require 'thread'
require 'zlib'

require 'socketry/error'

module Socketry
  
  class CompilerError < SocketryError; end
  
  class Compiler
    
    ##########

    # With this method, no compression is done, only encryption
    # The resulting output size (cumulative size of all pieces)
    # will be slightly bigger than the input size
    METHOD_NO_Z                   = 0
    # With this method, input is broken up into same size pieces,
    # and then each piece is compressed/encrypted independently;
    # as a result, the overall compression rate is likely to be
    # slightly better than for the BROKEN_METHOD_Z_SLOWER_LESS_PIECES
    # method, but the number of pieces produced will be the same
    # as if the METHOD_NO_Z method were used, and pieces
    # are likely to be a lot smaller than :max_piece_size parameter
    # For this method, as well as all other methods that involve
    # compression, if it is detected that the compressed piece size
    # is not smaller than the uncompressed piece size, compression
    # is not used in the end; it is determined on a per-piece 
    # basis whether to compress it or not
    METHOD_Z_FASTER_MORE_PIECES   = 1
    # a synonym of the above
    METHOD_Z                      = METHOD_Z_FASTER_MORE_PIECES
    # With this method, the compiler will attempt to make the size
    # of each output piece as close to :max_piece_size as possible;
    # as a result, there will likely be fewer output pieces than
    # if the METHOD_Z_FASTER_MORE_PIECES method were used, but the
    # trade-offs are slower speed and slightly worse compression
    # rate
    # NOTE: as of now, this method is considered broken as there 
    # seems no easy way to extract a piece using the piece_info
    # created during compilation
    BROKEN_METHOD_Z_SLOWER_LESS_PIECES   = 2
    
    METHODS = [
      METHOD_NO_Z,
      METHOD_Z
      ]

    ##########
    
    DEFAULTS = {
      :max_piece_size => 1024*1024,
      # see Zlib documentation
      :compression_level => Zlib::DEFAULT_COMPRESSION,
      # supported hash types are: md5, sha1
      :hash_type => :md5,
      :cipher_type => 'AES-256-CBC',
      :cipher_key => nil,
      :cipher_iv => nil,
      :method => nil
    }
    
    DEFAULT_METHOD = METHOD_Z
    
    ##########

    @@options = DEFAULTS
    
    def self.options
      @@options
    end

    ##########

    attr_reader :options

    ##########

    def initialize(options = {})
      @options = @@options.merge(options)
    end
    
    def compile(input_stream, options = {}, &block)
      options = @options.merge(options)
      method = (options[:method] || DEFAULT_METHOD).to_s
      method_signature = "compile_#{method}"
      raise CompilerError.new('Invalid method') unless self.respond_to?(method_signature)
      self.send(method_signature, input_stream, options, &block)
    end
    
    def compile_file(path, options = {}, &block)
      File.open(path, 'rb') do |file|
        compile(file, options, &block)
      end
    end
    
    def compile_string(string, options = {}, &block)
      compile(StringIO.new(string), options, &block)
    end

    ##########

    def check_piece(piece, piece_info, options = {})
      options = @options.merge(options)

      # calculate hash
      hash_builder = new_hash_builder(options[:hash_type])
      hash_builder.update(piece)
      
      if piece.size != piece_info[:output][:size] || hash_builder.digest != piece_info[:output][:hash]
        raise CompilerError.new('Piece check failed')
      end
      
      piece
    end
    
    ##########

    def extract_piece(input_stream, piece_info, options = {})
      options = @options.merge(options)
      
      # read input block
      input_stream.seek(piece_info[:input][:offset], IO::SEEK_SET)
      input_block = input_stream.read(piece_info[:input][:size])
      
      intermediate_block = input_block
      
      # compress if needed
      if piece_info[:output][:compressed]
        compressor = Zlib::Deflate.new(options[:compression_level])
        compressed_block = compressor.deflate(input_block, Zlib::FINISH)
        compressor.close
        intermediate_block = compressed_block
      end
      output_block = intermediate_block
      
      # encrypt
      cipher = OpenSSL::Cipher::Cipher.new(options[:cipher_type]).encrypt
      cipher.key = options[:cipher_key]
      cipher.iv = options[:cipher_iv]
      
      output_block = cipher.update(intermediate_block)
      output_block << cipher.final
      
      check_piece(output_block, piece_info, options)
    end
    
    def extract_piece_from_file(path, piece_info, options = {})
      File.open(path, 'rb') do |file|
        extract_piece(file, piece_info, options)
      end
    end

    def extract_piece_from_string(string, piece_info, options = {})
      extract_piece(StringIO.new(string), piece_info, options)
    end

    ##########

    def insert_piece(output_stream, piece, piece_info, options = {})
      options = @options.merge(options)
      
      # check piece integrity
      check_piece(piece, piece_info, options)
      
      # decrypt
      cipher = OpenSSL::Cipher::Cipher.new(options[:cipher_type]).decrypt
      cipher.key = options[:cipher_key]
      cipher.iv = options[:cipher_iv]
      
      intermediate_block = cipher.update(piece)
      intermediate_block << cipher.final
      
      output_block = intermediate_block

      # decompress if needed
      if piece_info[:output][:compressed]
        decompressor = Zlib::Inflate.new
        output_block = decompressor.inflate(intermediate_block)
        decompressor.close
      end
      
      # check output block
      if output_block.size != piece_info[:input][:size]
        raise CompilerError.new('Piece output size mismatch')
      end
      
      # write output block
      output_stream.seek(piece_info[:input][:offset], IO::SEEK_SET)
      output_stream.write(output_block)
    end
    
    def insert_piece_into_file(path, piece, piece_info, options = {})
      Thread.exclusive do
        File.open(path, 'r+b') do |file|
          insert_piece(file, piece, piece_info, options)
        end
      end
    end

    ##########

    def create_placeholder_file(path, size)
      # truncate is known not to work on all platforms
      #File.truncate(path, size)
      
      File.open(path, 'wb') do |file|
        if size > 0
          file.seek(size - 1)
          file.write("\0")
        end
      end
      
      raise CompilerError.new("Failed to create placeholder file of size #{size}") unless File.size(path) == size
      size
    end

    ##########

    def check_integrity(input_stream, size, hash, options = {}, &block)
      options = @options.merge(options)
      
      hash_builder = new_hash_builder(options[:hash_type])
      processed_size = 0
      
      input_stream.seek(0, IO::SEEK_SET)
      while buffer = input_stream.read(options[:max_piece_size])
        hash_builder.update(buffer)
        processed_size += buffer.size
        
        block.call(processed_size) if block
      end
      
      if processed_size != size || hash_builder.digest != hash
        raise CompilerError.new("Integrity check failed")
      end
      
      true
    end

    def check_file_integrity(path, size, hash, options = {}, &block)
      File.open(path, 'rb') do |file|
        check_integrity(file, size, hash, options, &block)
      end
    end

    def check_string_integrity(string, size, hash, options = {}, &block)
      check_integrity(StringIO.new(string), size, hash, options, &block)
    end

    ##########
    
    def compile_0(input_stream, options, &block)
      cipher = OpenSSL::Cipher::Cipher.new(options[:cipher_type]).encrypt
      options[:cipher_key] ||= cipher.random_key
      options[:cipher_iv] ||= cipher.random_iv
      hash_type = normalize_hash_type(options[:hash_type])

      input_block_size = options[:max_piece_size] - cipher.block_size
      raise_bad_max_piece_size if input_block_size <= 0
      
      input_size = 0
      input_hash_builder = new_hash_builder(hash_type)

      piece_infos = []
      while input_block = input_stream.read(input_block_size)
        input_hash_builder.update(input_block)
        
        intermediate_block = input_block
        
        # encrypt the piece
        cipher.key = options[:cipher_key]
        cipher.iv = options[:cipher_iv]
        
        output_block = cipher.update(intermediate_block)
        output_block << cipher.final
        raise_encryption_overflow if output_block.size > options[:max_piece_size]
        
        # calculate piece hash
        piece_hash_builder = new_hash_builder(hash_type)
        piece_hash_builder.update(output_block)

        piece_info = {
          :input => {
            :offset => input_size,
            :size => input_block.size
          },
          :output => {
            :size => output_block.size,
            :hash => piece_hash_builder.digest
          }
        }
        piece_infos << piece_info

        input_size += input_block.size
        
        block.call(input_size, piece_info) if block
      end
      
      { :options => options, :input => { :size => input_size, :hash => input_hash_builder.digest }, :pieces => piece_infos }
    end
    
    ##########
    
    def compile_1(input_stream, options, &block)
      cipher = OpenSSL::Cipher::Cipher.new(options[:cipher_type]).encrypt
      options[:cipher_key] ||= cipher.random_key
      options[:cipher_iv] ||= cipher.random_iv
      hash_type = normalize_hash_type(options[:hash_type])
      
      input_block_size = options[:max_piece_size] - cipher.block_size
      raise_bad_max_piece_size if input_block_size <= 0
      
      input_size = 0
      input_hash_builder = new_hash_builder(hash_type)
      
      piece_infos = []
      while input_block = input_stream.read(input_block_size)
        input_hash_builder.update(input_block)
        
        # attempt to compress the block
        compressor = Zlib::Deflate.new(options[:compression_level])
        compressed_block = compressor.deflate(input_block, Zlib::FINISH)
        compressor.close
        
        compressed = false
        if compressed_block.size >= input_block.size
          # compression was inefficient - use uncompressed data
          intermediate_block = input_block
        else
          intermediate_block = compressed_block
          compressed = true
        end

        # encrypt the block
        cipher.key = options[:cipher_key]
        cipher.iv = options[:cipher_iv]
        
        output_block = cipher.update(intermediate_block)
        output_block << cipher.final
        raise_encryption_overflow if output_block.size > options[:max_piece_size]
        
        # calculate block hash
        piece_hash_builder = new_hash_builder(hash_type)
        piece_hash_builder.update(output_block)

        piece_info = {
          :input => {
            :offset => input_size,
            :size => input_block.size
          },
          :output => {
            :size => output_block.size,
            :hash => piece_hash_builder.digest
          }
        }
        piece_info[:output][:compressed] = true if compressed
        piece_infos << piece_info

        input_size += input_block.size
        
        block.call(input_size, piece_info) if block
      end
      
      { :options => options, :input => { :size => input_size, :hash => input_hash_builder.digest }, :pieces => piece_infos }
    end
    
    ##########
    
    # def broken_compile_2(input_stream, options, &block)
    #   input_buffer = ''
    #   input_size = 0
    #   piece_infos = []
    #   input_hash_builder = new_hash_builder(hash_type)
    #   
    #   loop do 
    #     input_buffer, piece_input_size, piece_info = process_piece_2(input_buffer, input_size, input_hash_builder, input_stream, options)
    #     input_size += piece_input_size
    #     piece_infos << piece_info
    #     block.call(input_size, piece_info) if block
    #     break unless input_buffer
    #   end
    #   
    #   { :size => input_size, :hash => { :type => normalize_hash_type(hash_type), :value => input_hash_builder.digest }, :pieces => piece_infos }
    # end
    
    ##########
    private

    # def process_piece_2(input_buffer, input_offset, input_hash_builder, input_stream, options)
    #   compressed_size_hard_threshold = options[:max_piece_size] - 16
    #   compressed_size_soft_threshold = compressed_size_hard_threshold - 10*1024
    #   raise_bad_max_piece_size if compressed_size_soft_threshold <= 0
    # 
    #   input_block_size = 4096
    # 
    #   compressor = Zlib::Deflate.new(options[:compression_level])
    #   
    #   compressed_buffer = compressor.deflate(input_buffer, Zlib::SYNC_FLUSH) || ''
    #   processed_input_buffer = input_buffer
    #   input_buffer = ''
    #   
    #   loop do
    #     break if compressed_buffer.size >= compressed_size_soft_threshold
    #     
    #     input_buffer = input_stream.read(input_block_size)
    #     break unless input_buffer
    #       
    #     input_hash_builder.update(input_buffer)
    #     processed_input_buffer << input_buffer
    #     
    #     compressed_block = compressor.deflate(input_buffer, Zlib::SYNC_FLUSH)
    #     next unless compressed_block
    #     
    #     compressed_buffer << compressed_block
    #     break if compressed_buffer.size >= compressed_size_soft_threshold
    #   end
    #   
    #   compressed_buffer << compressor.deflate(nil, Zlib::FINISH)
    #   compressor.close
    #   raise_compression_overflow if compressed_buffer.size > compressed_size_hard_threshold
    #   
    #   intermediate_buffer = nil
    #   compressed = false
    #   if compressed_buffer.size >= processed_input_buffer.size
    #     intermediate_buffer = processed_input_buffer
    #   else
    #     intermediate_buffer = compressed_buffer
    #     compressed = true
    #   end
    #   
    #   # encrypt the block
    #   cipher = OpenSSL::Cipher::Cipher.new(CIPHER).encrypt
    #   cipher.key = cipher_key = options[:cipher_key] || cipher.random_key
    #   cipher.iv = cipher_iv = options[:cipher_iv] || cipher.random_iv
    #   
    #   final_buffer = cipher.update(intermediate_buffer)
    #   final_buffer << cipher.final
    #   raise_encryption_overflow if final_buffer.size > options[:max_piece_size]
    #   
    #   piece_hash_builder = new_hash_builder(hash_type)
    #   piece_hash_builder.update(final_buffer)
    #   piece_info = {
    #     :input => {
    #       :offset => input_offset,
    #       :size => processed_input_buffer.size
    #     },
    #     :output => {
    #       :size => final_buffer.size,
    #       :hash => {
    #         :type => normalize_hash_type(hash_type),
    #         :value => piece_hash_builder.digest
    #       }
    #     },
    #     :cipher => {
    #       :key => cipher_key,
    #       :iv => cipher_iv
    #     }
    #   }
    #   piece_info[:compressor] = { :level => options[:compression_level] } if compressed
    #   
    #   [input_buffer, processed_input_buffer.size, piece_info]
    # end

    ##########
    private
    
    def normalize_hash_type(type)
      type.to_s.downcase.to_sym
    end
    
    def new_hash_builder(type)
      function = case normalize_hash_type(type)
      when :md5   then Digest::MD5
      when :sha1  then Digest::SHA1
      else 
        raise CompilerError.new("Unknown hash type #{type}")
      end
      function.new
    end

    ##########
    private

    def raise_bad_max_piece_size
      raise CompilerError.new('Max piece size too small')
    end
    
    def raise_compression_overflow
      raise CompilerError.new('Compression overflow')
    end
    
    def raise_encryption_overflow
      raise CompilerError.new('Encryption overflow')
    end

    ##########
    
  end
  
end
