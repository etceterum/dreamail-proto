require 'yaml'

require 'socketry/error'
require 'socketry/logger'

module Socketry
  module Config
    
    class ConfigError < SocketryError
    end
    
    ROOT = defined?(SOCKETRY_ROOT) ? SOCKETRY_ROOT : Rails.root.to_s
    COMMON_ROOT = ROOT
    COMMON_CONFIG_ROOT = File.join(COMMON_ROOT, 'config', 'socketry')
    PRIVATE_ROOT = File.join(ROOT, 'socketry')
    PRIVATE_CONFIG_ROOT = File.join(PRIVATE_ROOT, 'config')
    PRIVATE_DATA_ROOT = File.join(PRIVATE_ROOT, 'data')
    PRIVATE_LOCAL_DATA_ROOT = File.join(PRIVATE_DATA_ROOT, 'local')
    PRIVATE_LOCAL_ASSETS_ROOT = File.join(PRIVATE_LOCAL_DATA_ROOT, 'assets')

    class Base
      
      # must be implemented by a descendant
      def dump
        self.abstract_method
      end
      
      def save(raise_on_error = false)
        self.class.save_yaml(self, raise_on_error)
      end
      
      def save!
        save(true)
      end
      
      def to_yaml
        dump.to_yaml
      end
      
      def self.load(raise_on_error = false)
        parse(load_yaml(raise_on_error) || default)
      end
      
      def self.load!
        load(true)
      end
      
      def self.path
        File.join(dirname, basename).freeze
      end
      
      # should be implemented by a descendant when appropriate
      def self.default
        {}
      end
      
      def self.type
        self.name.split('::').last.sub('Config', '').freeze
      end
      
      def self.dirname
        private? ? PRIVATE_CONFIG_ROOT : COMMON_CONFIG_ROOT
      end
      
      # should be implemented by a descendant if not private
      def self.private?
        true
      end
      
      def self.basename
        "#{type.underscore}.yml".freeze
      end
      
      def logger
        @logger ||= Config.logger
      end
      
      def self.logger
        @@logger ||= Socketry.logger
      end

      def self.logger=(logger)
        @@logger = logger
      end

      protected
      
      def self.abstract_method
        raise NotImplementedError.new('Abstract method')
      end
      
      def self.load_plain(path, raise_on_error)
        File.read(path)
      rescue Object => e
        message = "Failed to read data from file \"#{path}\""
        logger.error message
        raise ConfigError.new("#{message} (#{e})") if raise_on_error
        nil
      end

      def self.load_yaml(raise_on_error)
        data = load_plain(path, raise_on_error)
        if data
          begin
            YAML.load(data)
          rescue Object => e
            message = "Failed to parse #{type} configuration data from file \"#{path}\""
            logger.error message
            raise ConfigError.new("#{message} (#{e})") if raise_on_error
            nil
          end
        else
          nil
        end
      end
      
      def self.save_plain(path, data, raise_on_error)
        File.open(path, 'w') do |file|
          file.write(data)
        end
        logger.debug "Saved \"#{path}\""
        true
      rescue Object => e
        message = "Failed to write data into file \"#{path}\""
        logger.error message
        raise ConfigError.new("#{message} (#{e})") if raise_on_error
        false
      end
      
      def self.save_yaml(instance, raise_on_error)
        data = instance.to_yaml
        save_plain(path, data, raise_on_error)
      end
      
    end
    
  end
end
