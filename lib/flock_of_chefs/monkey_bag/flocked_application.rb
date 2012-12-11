require 'thread'

module FlockOfChefs
  module FlockedApplication

    def flocked_run_chef_client
      FlockOfChefs.global_chef_lock do
        unflocked_run_chef_client
      end
    end

    class << self
      def included(base)
        base.class_eval do
          unless(base.instance_methods.map(&:to_sym).include?(:unflocked_run_chef_client))
            alias_method :unflocked_run_chef_client, :run_chef_client
            alias_method :run_chef_client, :flocked_run_chef_client
          end
        end
      end

      def extended(base)
        base.instance_eval do
          unless(base.methods.map(&:to_sym).include?(:unflocked_run_chef_client))
            alias :unflocked_run_chef_client :run_chef_client
            alias :run_chef_client :flocked_run_chef_client
          end
        end
      end
    end
  end
end

if(defined?(Chef::Application))
  # Hook into Application classes
  %w(Client Solo WindowsService).each do |app|
    begin
      klass = Chef::Application.const_get(app)
      unless(klass.ancestors.include?(FlockOfChefs::FlockedApplication))
        klass.send(:include, FlockOfChefs::FlockedApplication)
      end
    rescue NameError
      # Not defined!
    end
  end

  # Hook into existing instances if we are loading up via
  # cookbook not client.rb
  ObjectSpace.each_object(Chef::Application) do |app_inst|
    unless(app_inst.respond_to?(:flocked_run_chef_client))
      app_inst.extend(FlockOfChefs::FlockedApplication)
    end
  end
end
