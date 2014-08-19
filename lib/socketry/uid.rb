require 'digest'

module Socketry
  
  class UID
    attr_reader :bin
    
    def initialize(salt)
      @bin = Digest::MD5.digest(salt)
    end
    
    def self.random
      srand
      salt = "/#{Time.now}/#{rand}/"
      UID.new(salt)
    end
    
    def self.from_hex(hex)
      # http://bitsfromthomas.blogspot.com/2007/09/ruby-code-snippet-translating-back-from.html
      hex_uid.unpack('a2'*(hex_uid.size/2)).collect {|i| i.hex.chr }.join
    end
    
    # # Creates a double-length UID with interleaved data
    # def ^(other)
    #   bin1_a = bin.split('')
    #   bin2_a = other.bin.split('')
    #   nbin_a = []
    #   bin1_a.each_with_index { |x, i| nbin_a << x << bin2_a[i] }
    #   UID.new(nbin_a.join(''))
    # end
    # 
    def hex
      Digest.hexencode(@bin)
    end
    
  end
  
end
