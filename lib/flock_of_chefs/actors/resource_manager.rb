require 'chef/search/query'

module FlockOfChefs
  class ResourceManager
    include Celluloid

    attr_accessor :notifications

    def initialize
      @notifications = Mash.new
      @runner = nil
      find_existing_runner!
    end

    def find_existing_runner!
      @runner = ObjectSpace.each_object(Chef::Runner).first
    end

    def new_run(runner)
      @runner = runner
    end

    # sending to remote
    #
    def send_subscribe_to_resource(loc_hash, loc_res, r_type, r_name, action, timing)
      loc_hash = Mash.new(loc_hash)
      determine_remote_nodes(loc_hash).each do |r_node|
        r_node[:resource_manager].register_subscription(
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
      loc_hash = Mash.new(loc_hash)
      add_to_notifications(loc_hash, l_resource.resource_name, l_resource.name, r_type, r_name, action, timing)
    end

    def notify_collection(collection, action)
      collection.each do |noti|
        determine_remote_nodes(noti[:location_hash]).each do |r_node|
          r_node[:resource_manager].receive_notification(
            noti[:remote_type],
            noti[:remote_name],
            action
          )
        end
      end
    end

    # receiving from remote
    #

    def register_subscription(node_id, l_type, l_name, r_type, r_name, action, timing)
      add_to_notifications(Mash.new(:node => node_id), l_type, l_name, r_type, r_name, action, timing)
    end

    def receive_notification(res_type, res_name, action)
      Chef::Log.info "Received remote notification for: #{res_type}[#{res_name}] - #{action}"
      FlockOfChefs.global_chef_lock do
        resource = @runner.run_context.resource_collection.lookup("#{res_type}[#{res_name}]")
        if(resource)
          @runner.run_action(resource, action)
          FlockOfChefs.get(:flock_api).raw_node.save
        end
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
      @notifications[l_type] ||= Mash.new
      @notifications[l_type][l_name] ||= Mash.new
      @notifications[l_type][l_name][action] ||= Mash.new
      @notifications[l_type][l_name][action][timing] ||= []
      @notifications[l_type][l_name][action][timing].push(
        Mash.new(
          :remote_type => r_type,
          :remote_name => r_name,
          :location_hash => loc_hash
        )
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

    # NOTE: Document this out some where people will actually read it
    # loc_hash valid structure:
    #   {:node => node.name}
    #   {:roles => %w(role1 role2)}
    #   {:recipes => %w(recipe1 recipe2)}
    #   {:query => 'direct string query'}
    #   {:environment => 'production'}
    # - if node is provided, everything else is ignored
    # - if multiple entries provided, they are ANDed together
    def determine_remote_nodes(loc_hash)
      if(loc_hash[:node])
        [FlockOfChefs[loc_hash[:node]]].compact
      else
        n_s = []
        if(loc_hash[:roles])
          n_s << loc_hash[:roles].map{|r|
            "roles:#{r}"
          }.join(' AND ')
        end
        if(loc_hash[:recipes])
          n_s << loc_hash[:recipes].map{|r|
            "recipes:#{r}"
          }.join(' AND ')
        end
        if(loc_hash[:environment])
          n_s << "chef_environment:#{loc_hash[:environment]}"
        end
        if(loc_hash[:query])
          n_s << loc_hash[:query]
        end
        Chef::Search::Query.new.search(:node, n_s).map{ |node|
          FlockOfChefs[node.name]
        }.compact
      end
    end

  end
end

FlockOfChefs::ResourceManager.supervise_as :resource_manager
