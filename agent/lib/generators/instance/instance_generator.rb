require 'openssl'

module Rails
  module Generator
    module Commands
      
      class Create
        
        def symlink(relative_source, relative_destination)
          source              = source_path(relative_source)
          destination         = destination_path(relative_destination)
          destination_exists  = File.symlink?(destination)
          
          # p source_root
          # p source
          
          if destination_exists
            logger.exists relative_destination
            return
          else
            logger.symlink [relative_source, relative_destination].join(' -> ')
          end
          
          # If we're pretending, back off now.
          return if options[:pretend]
          
          File.symlink(source, destination)
        end
        
        def generate_file(data, relative_destination, file_options = {}, &block)
          destination         = destination_path(relative_destination)
          destination_exists  = File.exist?(destination)

          # Check for and resolve file collisions.
          if destination_exists

            # Make a choice whether to overwrite the file.  :force and
            # :skip already have their mind made up, but give :ask a shot.
            choice = case (file_options[:collision] || options[:collision]).to_sym #|| :ask
              when :ask   then :skip #force_file_collision?(relative_destination, source, destination, file_options, &block)
              when :force then :force
              when :skip  then :skip
              else raise "Invalid collision option: #{options[:collision].inspect}"
            end

            # Take action based on our choice.  Bail out if we chose to
            # skip the file; otherwise, log our transgression and continue.
            case choice
              when :force then logger.force(relative_destination)
              when :skip  then return(logger.skip(relative_destination))
              else raise "Invalid collision choice: #{choice}.inspect"
            end

          # File doesn't exist so log its unbesmirched creation.
          else
            logger.generate relative_destination
          end

          # If we're pretending, back off now.
          return if options[:pretend]

          # Write destination file with optional shebang.  Yield for content
          # if block given so templaters may render the source file.  If a
          # shebang is requested, replace the existing shebang or insert a
          # new one.
          File.open(destination, 'wb') do |dest|
            dest.write data
          end

          # Optionally change permissions.
          if file_options[:chmod]
            FileUtils.chmod(file_options[:chmod], destination)
          end

        end
        
        def touch(dummy, relative_destination)
          destination         = destination_path(relative_destination)
          destination_exists  = File.exist?(destination)
          
          if destination_exists
            logger.exists relative_destination
          else
            logger.touch relative_destination
          end
          
          # If we're pretending, back off now.
          return if options[:pretend]
          
          FileUtils.touch(destination)
        end
        
        # directory that is ok to delete with all contents
        alias_method :trash_directory, :directory
        
      end
      
      class Destroy
        
        def symlink(relative_source, relative_destination)
          destination = destination_path(relative_destination)
          if File.symlink?(destination)
            logger.rm relative_destination
          else
            logger.missing relative_destination
            return
          end

          # If we're pretending, back off now.
          return if options[:pretend]
          
          FileUtils.rm(destination)

        end
        
        alias_method :touch, :file
        alias_method :generate_file, :file
        
        def trash_directory(relative_path)
          path = destination_path(relative_path)
          
          if File.exist?(path)
            if Dir[File.join(path, '*')].empty?
              logger.rmdir relative_path
              unless options[:pretend]
                FileUtils.rmdir(path)
              end
            else
              logger.rmtree relative_path
              unless options[:pretend]
                find_and_destroy_links_command = "find #{path} -type l | xargs rm"
                `#{find_and_destroy_links_command}`
                FileUtils.rmtree(path)
              end
            end
            directory(relative_path)
          else
            logger.missing relative_path
          end
        end
        
      end
      
    end
  end
end

class InstanceGenerator < Rails::Generator::Base
  DIRECTORIES = %w(db socketry/config/node)
  TRASH_DIRECTORIES = %w(log tmp/caches tmp/pids tmp/sessions tmp/sockets socketry/data/local/assets)
  TOUCHES = %w(db/development.sqlite3 db/schema.rb log/development.log)
  LINKS = %w(README Rakefile app config db/migrate db/seeds.rb doc lib public script test vendor)
  
  attr_reader :name, :port, :user, :password

  def initialize(runtime_args, runtime_options = {})
    super
    
    if runtime_options[:command] == :destroy
      usage if args.empty?
      @name = args.first
    else
      usage unless args.size == 4
      arguments = args.dup
    
      @name = arguments.shift
      @port = arguments.shift.to_i
      usage("Error: Invalid port number \"#{@port}\"") unless @port.is_a?(Fixnum) && @port > 0 && @port <= 0xFFFF
      @user = arguments.shift
      @password = arguments.shift
    end
  end
  
  def banner
    <<-EOS
Creates a new agent instance

USAGE: #{$0} #{spec.name} AgentName Port User Password [options]
EOS
  end  
  
  def add_options!(opt)
    options[:source] = Rails.root.to_s
  end
  
  def manifest
    record do |m|
      
      options[:source] = Rails.root.to_s
      
      for directory in DIRECTORIES
        m.directory in_instance_path(directory)
      end
      
      for directory in TRASH_DIRECTORIES
        m.trash_directory in_instance_path(directory)
      end
      
      for file in TOUCHES
        m.touch nil, in_instance_path(file)
      end
      
      for link in LINKS
        m.symlink link, in_instance_path(link)
      end
      
      passphrase = ActiveSupport::SecureRandom.hex(64)
      m.generate_file(passphrase, in_private_node_config_path('passphrase.txt'))
      
      private_key = OpenSSL::PKey::RSA.new(2048)
      cipher =  OpenSSL::Cipher::Cipher.new('des3')
      m.generate_file(private_key.to_pem(cipher, passphrase), in_private_node_config_path('private_key.pem'))
      
      public_key = private_key.public_key
      m.generate_file(public_key.to_pem, in_private_node_config_path('public_key.pem'))
      
      m.template(File.join('templates', 'user.yml'), in_private_config_path('user.yml'))
      m.template(File.join('templates', 'node.yml'), in_private_config_path('node.yml'))
      
      m.file(File.join('templates', 'ping.yml'), in_private_config_path('ping.yml'))

      # m.template(File.join('templates', 'database.yml'), File.join(instance_path, 'config', 'database.yml'))
      
    end
  end
  
  private 
  def instance_name
    @name
  end
  
  def instance_path
    File.join('instances', instance_name)
  end
  
  def in_instance_path(relative_path)
    File.join(instance_path, relative_path)
  end
  
  def private_path
    in_instance_path('socketry')
  end
  
  def in_private_path(relative_path)
    File.join(private_path, relative_path)
  end
  
  def private_config_path
    in_private_path('config')
  end
  
  def in_private_config_path(relative_path)
    File.join(private_config_path, relative_path)
  end
  
  def private_node_config_path
    in_private_config_path('node')
  end
  
  def in_private_node_config_path(relative_path)
    File.join(private_node_config_path, relative_path)
  end
  
end
