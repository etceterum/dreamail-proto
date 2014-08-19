require 'highline/import'

require 'socketry/error'
require 'socketry/logger'

require 'socketry/config/user'
require 'socketry/config/node'

module Socketry
  
  ##########
  
  class RegistrationError < SocketryError
  end

  ##########
  
  class Registrar
    
    ##########

    def self.logger
      @@logger ||= Socketry.logger
    end
    
    def self.logger=(logger)
      @@logger = logger
    end
    
    ##########

    def logger
      @logger ||= self.class.logger
    end
    
    attr_writer :logger
    
    ##########

    def initialize(user_config, node_config)
      @user_config = user_config
      @node_config = node_config
    end
    
    def register
      
      if @node_config.registered?
        if @user_config.registered?
          logger.debug "Both user and node are already registered"
          return
        else
          error "Node is already registered but user credentials are not set"
        end
      end

      unless @user_config.registered?
        puts "User not registered. Please enter user credentials:"

        login = nil
        loop do
          login = ask("  Login: ") { |q| q.echo = true }
          unless login =~ Socketry::Regex.email
            puts "Login must be a proper e-mail address. Try again"
            next
          end
          break
        end


        password = nil
        loop do
          password = ask("  Password: ") { |q| q.echo = '*' }
          password_confirmation = ask("  Confirm password: ") { |q| q.echo = '*' }
          unless password == password_confirmation
            puts "Passwords do not match. Try again."
            next
          end
          break
        end

        @user_config.login = login
        @user_config.password = password

        begin
          Socketry::Client.master.register_user
        rescue Socketry::Unchanged => e
          logger.info "User #{login} is already registered, credentials are valid"
        rescue Socketry::BadRequest, Socketry::BadIdentity, Object => e
          error "Failed to register user: #{e}"
        else
          logger.info "Successfully registered user #{@user_config.login}"
        end

        begin
          @user_config.save!
        rescue Object => e
          error "Failed to save user configuration"
        end

      end

      unless @node_config.registered?

        begin
          @node_config.uid = Socketry::Client.master.register_node
        rescue Object => e
          error "Failed to register node: #{e}"
        else
          logger.info "Successfully registered node #{@node_config.uid}"
        end

        begin
          @node_config.save!
        rescue Object => e
          error "Failed to save node configuration"
        end

      end
      
    end

    ##########
    
    private

    def error(message)
      logger.error message
      raise RegistrationError.new(message)
    end
    
    ##########
    
  end
  
  ##########
  
  def self.registrar
    @@registrar ||= Registrar.new(Config.user, Config.node)
  end
  
  ##########

end

