module Socketry
  module Script

    def execute(banner, command, cd = nil)
      puts banner
      if cd
        command = "cd #{cd.to_s} && #{command}"
      end
      do_execute command
    end

    def script(banner, script, cd = nil)
      execute banner, "./script/#{script}", cd
    end

    def socketry_script(banner, script, cd)
      execute banner, "./script/socketry/#{script}", cd
    end
    
    def agent_instance_execute(banner, command, instance)
      execute banner, command, "./agent/instances/#{instance}"
    end
    
    def agent_instance_script(banner, script, instance)
      socketry_script banner, script, "./agent/instances/#{instance}"
    end
    
    private
   
    def do_execute(command)
      puts ">> '#{command}'"
      system("#{command} 2> /dev/null")
    end
    
  end
end
