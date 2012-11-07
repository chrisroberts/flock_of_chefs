module FlockOfChefs
  module FlockedRunner
    def flocked_init(*args)
      original_initialize(*args)
      if(FlockOfChefs.me)
        FlockOfChefs.me[:flock_api].active = true
        FlockOfChefs.get(:resource_manager).new_run(self)
      end
    end

    def flocked_run_action(*args)
      original_run_action(*args)
      Chef::Log.info "Sending immediate flock notifications for #{args.first.resource_name}[#{args.first.name}]"
      FlockOfChefs.get(:resource_manager).send_notifications(
        args[0], args[1], :immediately
      )
    end

    class << self
      def included(base)
        base.class_eval do
          alias_method :original_initialize, :initialize
          alias_method :initialize, :flocked_init
          alias_method :original_run_action, :run_action
          alias_method :run_action, :flocked_run_action
        end
      end
    end
  end
end

if(defined?(Chef::Runner))
  unless(Chef::Runner.ancestors.include?(FlockOfChefs::FlockedRunner))
    Chef::Runner.send(:include, FlockOfChefs::FlockedRunner)
  end
end
