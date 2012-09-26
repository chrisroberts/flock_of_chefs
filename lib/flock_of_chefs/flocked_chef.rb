require 'thread'
# This is for hacking up chef internals
# NOTE: Currently this is only mucking around with
#   Chef::Application::Client. Hopefully CHEF-3478
#   will get merged and make it much easier to add
#   the custom functionality we want
module FlockOfChefs
  module FlockedChef
    def mutex
      unless(@mutex)
        @mutex = Mutex.new
      end
      @mutex
    end
    def run_chef_client
      mutex.synchronize do
        @chef_client = Chef::Client.new(
          @chef_client_json, 
          :override_runlist => config[:override_runlist]
        )
        @chef_client_json = nil
        @chef_client.run
        @chef_client = nil
      end
    end

    def run_application
      unless Chef::Platform.windows?
        SELF_PIPE.replace IO.pipe

        trap("USR1") do
          Chef::Log.info("SIGUSR1 received, waking up")
          SELF_PIPE[1].putc('.') # wakeup master process from select
        end
      end

      if Chef::Config[:version]
        puts "Chef version: #{::Chef::VERSION}"
      end

      if Chef::Config[:daemonize]
        Chef::Daemon.daemonize("chef-client")
      end

      loop do
        begin
          if Chef::Config[:splay]
            splay = rand Chef::Config[:splay]
            Chef::Log.debug("Splay sleep #{splay} seconds")
            sleep splay
          end
          run_chef_client
          if Chef::Config[:interval]
            Chef::Log.debug("Sleeping for #{Chef::Config[:interval]} seconds")
            unless SELF_PIPE.empty?
              client_sleep Chef::Config[:interval]
            else
              # Windows
              sleep Chef::Config[:interval]
            end
          else
            Chef::Application.exit! "Exiting", 0
          end
        rescue Chef::Application::Wakeup => e
          Chef::Log.debug("Received Wakeup signal.  Starting run.")
          next
        rescue SystemExit => e
          raise
        rescue Exception => e
          if Chef::Config[:interval]
            Chef::Log.error("#{e.class}: #{e}")
            Chef::Application.debug_stacktrace(e)
            Chef::Log.error("Sleeping for #{Chef::Config[:interval]} seconds before trying again")
            unless SELF_PIPE.empty?
              client_sleep Chef::Config[:interval]
            else
              # Windows
              sleep Chef::Config[:interval]
            end
            retry
          else
            Chef::Application.debug_stacktrace(e)
            Chef::Application.fatal!("#{e.class}: #{e.message}", 1)
          end
        end
      end
    end
  end
end

Chef::Application::Client.send(:include, FlockOfChefs::FlockedChef)
