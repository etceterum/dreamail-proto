require 'thread'

# make sure sqlite's execute is always run in thread-exclusive mode so we
# don't ever get SQLiteBusy exception
module ActiveRecord
  module ConnectionAdapters
    class SQLiteAdapter

      # compare against sqlite_adapter.rb
      def execute(sql, name = nil) #:nodoc:
        Thread.exclusive do
          catch_schema_changes { log(sql, name) { @connection.execute(sql) } }
        end
      end
      
    end
  end
end
