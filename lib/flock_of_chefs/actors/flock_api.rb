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

    def run_chef!
      chef_app.run_chef_client
    end

    def active?
      active
    end
  end
end

FlockOfChefs::FlockApi.supervise_as :flock_api
