require 'chef/handler'

module FlockOfChefs
  class FlockedReport < Chef::Handler
    def report
      if(DCell.me.nil?)
        setup_dcell!
      end
      dnode = DCell.me
      if(dnode)
        dnode[:flock_api].node = node.to_hash
        Chef::Log.info 'Node information successfully stored in flock'
      else
        Chef::Log.warn 'Failed to store node information in flock!'
      end
    end

    def setup_dcell!
      raise 'Flock of chefs cookbook not in use!' unless node[:flock_of_chefs]
      if(node.recipes.include?('flock_of_chefs::keeper'))
        # NOTE: just gossip for now, zookeeper later
        DCell.start(
          :node => node.name,
          :addr => "tcp://#{node[:ipaddress]}:#{node[:flock_of_chefs][:port]}"
        )
      else
        keeper_node = Chef::Search::Query.new.search(:node, 'recipes:flock_of_chefs\:\:keeper').first.first
        raise 'Failed to find flock keeper!' unless keeper_node
        DCell.start(
          :node => node.name,
          :addr => "tcp://#{node[:ipaddress]}:#{node[:flock_of_chefs][:port]}",
          :directory => {
            :id => keeper_node.name,
            :address => "tcp://#{keeper_node[:ipaddress]}:#{keeper_node[:flock_of_chefs][:port]}"
          }
        )
      end
    end
  end
end
