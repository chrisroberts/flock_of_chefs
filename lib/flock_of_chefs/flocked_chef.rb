require 'thread'

module FlockOfChefs
  module FlockedChef
    def mutex
      unless(@mutex)
        @mutex = Mutex.new
      end
      @mutex
    end

    def run_chef_client
      mutex.synchronize do
        @chef_client = Chef::Client.new(
          @chef_client_json, 
          :override_runlist => config[:override_runlist]
        )
        @chef_client_json = nil
        @chef_client.run
        @chef_client = nil
      end
    end
  end
end

%w(Client Solo WindowsService).each do |app|
  begin
    klass = Chef::Application.const_get(app)
    klass.send(:include, FlockOfChefs::FlockedChef)
  rescue NameError
    # Not defined!
  end
end
