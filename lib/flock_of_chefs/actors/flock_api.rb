module FlockOfChefs
  class FlockApi
    include Celluloid

    attr_reader :active

    # app:: Chef::Application instance
    # Set chef app
    def chef_app=(app)
      @chef_app = app
    end

    # node:: Chef::Node
    # Set chef node
    def node=(node)
      @node = node
    end
  
    # bool:: Boolean
    # Set if chef is currently running
    def active=(bool)
      @active = !!bool
    end

    # Perform a chef run
    def run_chef
      begin
        Thread.new do
          @chef_app.run_chef_client
        end
        true
      rescue
        false
      end
    end

    # attribute_string:: Period delimited attribute key
    # Return node hash or attribute based on passed key
    def node(attribute_string=nil)
      if(attribute_string)
        begin
          res = attribute_string.to_s.split('.').delete_if(&:empty?).inject(@node) do |memo,arg|
            memo.send(arg)
          end
          res.is_a?(Chef::Node::Attribute) ? res.to_hash : res
        rescue => e
          e
        end
      else
        node_hash
      end
    end

    # Returns full node Hash
    def node_hash
      Mash.new(node.to_hash)
    end

    # Returns raw node. Only useful internally on given node.
    def raw_node
      @node
    end

    # node_info: Mash of node data cut down
    def discovery_notifications(node_info)
      matches = []
      raw_node[:flock_of_chefs][:subscriptions].each do |loc_hash, sub|
        match = false
        if(loc_hash[:name])
          match = node_info[:name] == loc_hash[:node]
        end
        [:roles, :recipes].each do |key|
          if(loc_hash[key])
            match = !(Array(node_info[key]) & Array(loc_hash[key])).empty?
          end
        end
        if(loc_hash[:environment])
          match = loc_hash[:environment] == node_info[:chef_environment]
        end
        matches << sub if match
      end
      matches
    end

  end
end

FlockOfChefs::FlockApi.supervise_as :flock_api
