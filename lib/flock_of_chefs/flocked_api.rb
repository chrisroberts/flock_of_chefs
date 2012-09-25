module FlockOfChefs
  class FlockedApi
    include Celluloid
    attr_accessor :chef_app
    attr_accessor :node

    def run_chef!
      chef_app.run_client!
    end
  end
end

FlockOfChefs::FlockedApi.supervise_as :flock_api
