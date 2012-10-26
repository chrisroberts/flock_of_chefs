# NOTE: loc_hash support starts with :node only!
# NOTE: we need to add timing for notification/subscriptions. i think 
#   we can do this by creating new block resources and throwing them at the
#   end of the current run context for delayed
module FlockOfChefs
  module FlockedResources
    def flocked_init(*args)
      super
      dnode = DCell.me
      if(dnode)
        dnode[:resource_manager].register_resource(self)
      end
    end

    def flocked_run_action(*args)
      original_run_action(*args)
      if(updated_by_last_action? && DCell.me)
        DCell.me[:resource_manager].notify_subscribers(self)
      end
    end

    def remote_subscribes(action, resource, loc_hash={})
      r_type,r_name = break_resource_string(resource)
      DCell::Node[loc_hash[:node]][:resource_manager].subscription(
        DCell.me.id, r_type, r_name, 
        convert_to_snake_case(self.class), 
        name, action
      )
    end

    def remote_notifies(action, resource, loc_hash={})
      r_type,r_name = break_resource_string(resource)
      DCell::Node[loc_hash[:node]][:resource_manager].notify_resource(
        r_type, r_name, action
      )
    end

    def break_resource_string(resource)
      raise TypeError.new('Expecting a string value') unless resource.is_a?(String)
      resource.scan(/([^\[]+)\[([^\]]+)\]/).flatten
    end

    class << self
      def included(base)
        base.class_eval do
          alias_method :original_run_action, :run_action
          alias_method :run_action, :flocked_run_action
        end
      end
    end
  end
end

# Make all resources actors
# TODO: Give them wait staff jobs while they wait for their big break
#Chef::Resource.send(:include, Celluloid)

# Hook in custom functionality to all resources
[
  Chef::Resource,
  Chef::Resource.constants.map{|const|
    klass = Chef::Resource.const_get(const)
    klass if klass.is_a?(Class) && klass < Chef::Resource
  }.compact
].flatten.each do |klass|
  unless(klass.ancestors.include?(FlockOfChefs::FlockedResources))
    klass.send(:include, FlockOfChefs::FlockedResources)
  end
end
