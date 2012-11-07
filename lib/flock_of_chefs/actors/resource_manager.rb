module FlockOfChefs
  class ResourceManager
    include Celluloid

    attr_accessor :runner

    def initialize
      @stale_resources = {}
      @subscriptions = {}
      @notifications = {}
      @runner = nil
      find_existing_runner!
    end

    def find_existing_runner!
      @runner = ObjectSpace.each_object(Chef::Runner).first
    end

    def new_run(runner)
      @runner = runner
    end

    ## New work start
  
    # sending to remote
    #
    def send_subscribe_to_resource(loc_res, r_type, r_name, action, timing)
      determine_remote_nodes(loc_res).each do |r_node|
        r_node.register_subscription(
          FlockOfChefs.me.id, r_type, r_name, loc_res.resource_name,
          loc_res.name, action, timing
        )
      end
    end

    def send_notifications(resource, action, timing)
      collection = find_notify_collection(resource, action, timing)
      notify_collection(collection, action) if collection
    end

    def register_notification(loc_hash, l_resource, r_type, r_name, action, timing)
      add_to_notitfications(loc_hash, l_resource.resource_name, l_resource.name, r_type, r_name, action, timing)
    end

    def notify_collection(collection, action)
      collection.each do |noti|
        determine_remote_nodes(noti[:location_hash]).each do |r_node|
          r_node.receive_notification(
            noti[:remote_type],
            noti[:remote_name],
            action
          )
        )
      end
    end

    # receiving from remote
    #

    def register_subscription(node_id, l_type, l_name, r_type, r_name, action, timing)
      add_to_notitfications({:node => node_id}, l_type, l_name, r_type, r_name, action, timing)
    end

    def receive_notification(res_type, res_name, action)
      resource = @runner.run_context.resource_collection.lookup("#{res_type}[#{res_name}]")
      if(resource)
        @runner.run_action(resource, action)
      end
    end

    ## Both
    #
    # loc_hash:: Hash definition for node location
    # l_type:: Local resource type
    # l_name:: Local resource name
    # r_type:: Remote resource type
    # r_name:: Remote resource name
    # action:: Action to run on remote resource
    # timiming:: Timing of notification (:immediately or :delayed)
    def add_to_notifications(loc_hash, l_type, l_name, r_type, r_name, action, timing)
      @notifications[l_type] ||= {}
      @notifications[l_type][l_name] ||= {}
      @notifications[l_type][l_name][action] ||= {}
      @notifications[l_type][l_name][action][timing] ||= []
      @notifications[l_type][l_name][action][timing].push(
        :remote_type => r_type,
        :remote_name => r_name,
        :location_hash => loc_hash
      )
      @notifications[l_type][l_name][action][timing].uniq!
    end

    def find_notify_collection(resource, action, timing)
      [resource.resource_name, resource.name, action, timing].inject(@notifications) do |m,o|
        if(m && m[o])
          m[o]
        else
          nil
        end
      end
    end

    # TODO: Make this do proper searching instead of only direct node
    def determine_remote_nodes(loc_hash)
      [FlockOfChefs[loc_hash[:node]]].compact
    end

  end
end

FlockOfChefs::ResourceManager.supervise_as :resource_manager
