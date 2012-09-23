module FlockOfChefs
  class FlockedApi
    include Celluloid
    attr_accessor :chef_app
    attr_accessor :node
  end
end

FlockOfChefs::FlockedApi.supervise_as :flock_api
