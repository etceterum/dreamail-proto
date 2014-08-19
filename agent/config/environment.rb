# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

unless defined?(SOCKETRY_ROOT)
  SOCKETRY_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  SOCKETRY_IN_INSTANCE = File.basename(File.dirname(SOCKETRY_ROOT)) == 'instances'
end

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

module Rails
  class Configuration
    def set_root_path!
      raise 'SOCKETRY_ROOT is not set' unless defined?(::SOCKETRY_ROOT)
      raise 'SOCKETRY_ROOT is not a directory' unless File.directory?(::SOCKETRY_ROOT)

      @root_path = File.expand_path(::SOCKETRY_ROOT)

      Object.const_set(:RELATIVE_RAILS_ROOT, ::SOCKETRY_ROOT.dup) unless defined?(::RELATIVE_RAILS_ROOT)
      ::RAILS_ROOT.replace @root_path
    end
  end
end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  # config.gem 'mysql'
  config.gem 'subdomain-fu'
  config.gem 'hirb', :lib => 'hirb', :version => '>= 0.3.2', :source => "http://gems.github.com"
  config.gem 'highline'
  config.gem 'mongrel'
  config.gem 'formtastic', :source => 'http://gemcutter.org'
  config.gem 'bluecloth'
  config.gem 'json'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  config.action_controller.allow_forgery_protection = false
end
