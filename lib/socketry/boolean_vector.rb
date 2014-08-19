require 'socketry/encoder'

module Socketry
  class BooleanVector
    include Enumerable
    
    attr_reader :size, :data
    
    def initialize(size, initial = false)
      full_byte_count = size >> 3
      # puts "full byte count: #{full_byte_count}"
      part_byte_mask = size & 7
      # puts "part byte mask: #{part_byte_mask}"
      has_part_byte = 0 != part_byte_mask
      if has_part_byte
        part_byte_value = 0.chr
        if initial
          part_byte_value = (0xFF >> (8 - (size - (full_byte_count << 3)))).chr
        end
      else
        part_byte_value = ''
      end
      
      @size = size
      @data = String.new((initial ? 0xFF.chr : 0.chr)*full_byte_count + part_byte_value).force_encoding('BINARY')
      #@data = String.new((initial ? 0xFF.chr : 0.chr)*((size >> 3) + (0 == (size & 7) ? 0 : 1))).force_encoding('BINARY')
    end
    
    def [](index)
      0 != @data.getbyte(index >> 3) & (1 << (index & 7))
    end
    
    def []=(index, value)
      byte_index = index >> 3
      old_byte = @data.getbyte(byte_index)
      bit_mask = 1 << (index & 7)
      if value
        new_byte = old_byte | bit_mask
      else
        new_byte = old_byte & ~bit_mask
      end
      @data.setbyte(byte_index, new_byte)
    end
    
    def each
      i = 0
      full_byte_count = size >> 3
      last_byte_bit_count = size & 7
      @data.each_byte do |byte|
        bit_count = i < full_byte_count ? 8 : last_byte_bit_count
        0.upto(bit_count - 1) do |j|
          value = 1 == (byte & 1)
          byte = byte >> 1
          yield value
        end
        i += 1
      end
    end
    
    def hexdata
      Encoder.bin_to_hex(data)
    end
    
    def empty?
      0 == size
    end
    
    def false?
      !include?(true)
    end
    
    def true?
      !include?(false)
    end
    
    # returns indices of all true bits
    def true_indices
      (0...size).select { |i| self[i] }
    end

    # returns indices of all true bits
    def false_indices
      (0...size).select { |i| !self[i] }
    end

    # TODO optimize
    def ~()
      result = self.class.new(size)
      each_with_index do |bit, i|
        result[i] = !bit
      end
      result
    end
    
    # TODO optimize
    def &(other)
      result = self.class.new(other.size > size ? other.size : size)
      0.upto(result.size - 1) do |i|
        result[i] = self[i] & other[i]
      end
      result
    end
    
  end
end
