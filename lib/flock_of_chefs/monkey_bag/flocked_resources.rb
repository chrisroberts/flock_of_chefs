module FlockOfChefs
  module FlockedResources

    def remote_subscribes(action, resource, *args)
      loc_hash = args.detect{|elm| elm.is_a?(Hash)}
      raise TypeError.new 'Location hash is required!' unless loc_hash
      args.delete(loc_hash)
      timing = args.first || :immediately
      r_type,r_name = break_resource_string(resource)
      # TODO: Update this to accept discovery based attributes instead of just 'node'
      FlockOfChefs.get(:resource_manager).send_subscribe_to_resource(
        loc_hash, self, r_type, r_name, action, timing
      )
    end

    def remote_notifies(action, resource, *args)
      loc_hash = args.detect{|elm| elm.is_a?(Hash)}
      raise TypeError.new 'Location hash is required!' unless loc_hash
      args.delete(loc_hash)
      timing = args.first || :immediately
      r_type,r_name = break_resource_string(resource)
      FlockOfChefs.get(:resource_manager).register_notification(
        loc_hash, self, r_type, r_name, action, timing
      )
    end

    def break_resource_string(resource)
      raise TypeError.new('Expecting a string value') unless resource.is_a?(String)
      resource.scan(/([^\[]+)\[([^\]]+)\]/).flatten
    end

  end
end

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
