module FlockOfChefs
  module FlockedRunner
    def flocked_initialize(*args)
      unflocked_initialize(*args)
      if(FlockOfChefs.me)
        FlockOfChefs.me[:flock_api].active = true
        FlockOfChefs.get(:resource_manager).new_run(self)
      end
    end

    def flocked_run_action(*args)
      unflocked_run_action(*args)
      Chef::Log.info "Sending immediate flock notifications for #{args.first.resource_name}[#{args.first.name}]"
      rm = FlockOfChefs.get(:resource_manager)
      rm.send_notifications(args[0], args[1], :immediately) if rm
    end

    class << self
      def included(base)
        base.class_eval do
          unless(base.instance_methods.map(&:to_sym).include?(:unflocked_initialize))
            alias_method :unflocked_initialize, :initialize
            alias_method :initialize, :flocked_initialize
            alias_method :unflocked_run_action, :run_action
            alias_method :run_action, :flocked_run_action
          end
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
