module FlockOfChefs
  class FlockApi
    include Celluloid

    attr_reader :active

    def chef_app=(app)
      @chef_app = app
    end

    def node=(node)
      @node = node
    end
   
    def active=(bool)
      @active = !!bool
    end

    def run_chef
      chef_app.run_chef_client
    end

    def node(attribute_string=nil)
      if(attribute_string)
        attribute_string.to_s.split('.').delete_if(&:empty?).inject(node) do |memo,arg|
          memo.send(arg)
        end
      else
        node_hash
      end
    end

    def node_hash
      node.to_hash
    end

  end
end

FlockOfChefs::FlockApi.supervise_as :flock_api
