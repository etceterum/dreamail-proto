require 'digest'

module Socketry
  module Encoder
    
    def self.encode(data)
      Marshal.dump(data)
    end
    
    def self.decode(data)
      Marshal.load(data)
    end
    
    def self.bin_to_hex(bin)
      Digest.hexencode(bin)
    end
    
    def self.hex_to_bin(hex)
      # http://bitsfromthomas.blogspot.com/2007/09/ruby-code-snippet-translating-back-from.html
      hex.unpack('a2'*(hex.size/2)).collect {|i| i.hex.chr }.join
    end
    
  end
end
