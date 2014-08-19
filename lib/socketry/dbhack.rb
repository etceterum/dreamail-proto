require 'thread'
require 'active_record'

module Socketry
  module DB
    def self.release_connection
      ::ActiveRecord::Base.connection_pool.release_connection
    rescue
      # no-op
    end
  end
end

# this monkeypatch ensures that database connection is released when a thread dies
class Thread
  def initialize_with_connection_release(*args)
    initialize_without_connection_release do
      begin
        yield(*args)
      ensure
        # puts "-- releasing database connection --"
        Socketry::DB.release_connection rescue nil
      end
    end
  end

  alias_method_chain :initialize, :connection_release
end
