module FlockOfChefs
  class ResourceManager
    include Celluloid
    trap_exit :dead_resource

    attr_accessor :runner

    def initialize
      @resources = {}
      @stale_resources = {}
      @runner = nil
    end

    def new_run(runner)
      @runner = runner
      @stale_resources = @resources
      @resources = {}
    end

    def completed_run
      clean_stale_resources
      @stale_resources = {}
    end

    def register_resource(resource)
      t_name = get_name(resource)
      @resources[t_name] ||= {}
      @resources[t_name][resource.name] = resource
      kill_stale_resource(t_name, resource.name)
    end

    def kill_stale_resource(t_name, r_name)
      if(@stale_resources[t_name] && @stale_resources[t_name][r_name])
        if(@stale_resources[t_name][r_name].alive?)
          @stale_resources[t_name][r_name].terminate
        end
        @stale_resources[t_name].delete(r_name)
      end
    end

    def dead_resource(actor, reason)
      kill_stale_resource(get_name(actor), actor.name)
    end

    def receive_remote_notification(t_name, r_name, action)
      collection = [@stale_resources, @resources].detect{ |item|
        item[t_name] && item[t_name][r_name]
      }
      if(collection)
        @runner.run_action(collection[t_name][r_name], action)
      end
    end

    def subscription(remote_node_id, resource_type, resource_name, call_type, call_name, action)
      @subscriptions[resource_type] ||= {}
      @subscriptions[resource_type][resource_name] ||= []
      @subscriptions[resource_type][resource_name].push(
        :node_id => remote_node_id,
        :call_type => call_type,
        :call_name => call_name,
        :action => action
      )
      @subscriptions[resource_type][resource_name].uniq!
    end

    def notify_subscribers(resource_type, resource_name)
      if(@subscriptions[resource_type][resource_name])
        @subscriptions[resource_type][resource_name].each do |info|
          DCell::Node[info[:node_id]][:resource_manager].notify_resource(
            info[:call_type], info[:call_name], info[:action]
          )
        end
      end
    end

    def notify_resource(resource_type, resource_name, action)
      receive_remote_notification(
        resource_type, resource_name, action
      )
    end

    def clean_stale_resources
      @stale_resources.values.each do |collection|
        collection.values.map do |actor|
          actor.terminate if actor.alive?
        end
      end
      @stale_resources = {}
    end

    def get_name(resource)
      # TODO: Check how the naming convention goes for LWRPs
      Chef::Mixin::ConvertToClassName.convert_to_snake_case(
        resource.class.to_s.split('::').last
      )
    end
  end
end

FlockOfChefs::ResourceManager.supervise_as :resource_manager
