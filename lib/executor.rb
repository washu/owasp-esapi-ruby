# Executor implmentation
#
# Provide a safe execute command, that wll ensure paths and args are escaped properly
# and check for expansions of the command
#

module Owasp
  module Esapi
    # Executor class
    class Executor

      # Wrapper for Process#spawn
      # it sanitizes the parames and validates paths before execution
      def execute_command(cmd,params,working_dir=nil,codec=nil,log_params=false,redirect_error=false)
        cmd_path = File.expand_path(cmd)

      end
    end
  end
end
