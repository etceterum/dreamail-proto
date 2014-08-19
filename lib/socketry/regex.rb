module Socketry
  module Regex

    # Taken from authlogic source code; all credit goes to the author
    # http://github.com/binarylogic/authlogic/blob/master/lib/authlogic/regex.rb
    def self.email
      return @email_regex if @email_regex
      email_name_regex  = '[A-Z0-9_\.%\+\-]+'
      domain_head_regex = '(?:[A-Z0-9\-]+\.)+'
      domain_tld_regex  = '(?:[A-Z]{2,4}|museum|travel)'
      @email_regex = /^#{email_name_regex}@#{domain_head_regex}#{domain_tld_regex}$/i
    end
  end
end
