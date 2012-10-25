require 'chef/handler'

module FlockOfChefs

  class FlockedReport < Chef::Handler
    def flocker(currently_active)
      unless(DCell.me)
        FlockOfChefs.start_flocking!(node)
      end
      dnode = DCell.me
      if(dnode)
        dnode[:flock_api].node = node
        dnode[:flock_api].active = currently_active
        Chef::Log.info 'Node information successfully stored in flock'
      else
        Chef::Log.warn 'Failed to store node information in flock!'
      end
    end
  end

  class StartConverge < FlockedReport
    def report
      flocker(true)
    end
  end

  class StopConverge < FlockedReport
    def report
      flocker(false)
    end
  end

  class << self
    def find_flock_bind_addr(node)
      if(i = node[:flock_of_chefs][:bind_addr][:device])
        node.network.interfaces.send(i).addresses.keys[1]
      elsif(node[:flock_of_chefs][:bind_addr][:ip_address])
        node[:flock_of_chefs][:bind_addr][:ip_address]
      else
        node.ip_address
      end
    end

    def find_flock_registry_addr(node, registry_node)
      if(node[:flock_of_chefs][:registry][:ip_address])
        node[:flock_of_chefs][:registry][:ip_address]
      else
        registry_node.ip_address
      end
    end

    def start_flocking!(node)
      raise 'Flock of chefs cookbook not in use!' unless node[:flock_of_chefs]
      bind_addr = find_flock_bind_addr(node)
      if(node.recipes.include?('flock_of_chefs::keeper'))
        # We are the keeper!
        start_args = {
          :node => node.name,
          :addr => "tcp://#{bind_addr}:#{node[:flock_of_chefs][:port]}"
        }
        # TODO: Add in the other adapters
        case node[:flock_of_chefs][:registry][:type].to_s
        when 'zk'
          require 'dcell/registries/zk_adapter'
          start_args.merge!(
            :registry => {
              :adapter => 'zk',
              :server => '127.0.0.1:2181'
            }
          )
        else
          start_args.merge!(
            :registry => {
              :adapter => 'gossip'
            }
          )
        end
        DCell.start(start_args)
      else
        keeper_node = Chef::Search::Query.new.search(:node, 
          'recipes:flock_of_chefs\:\:keeper'
        ).first.first
        registry_ip = find_flock_registry_addr(node, keeper_node)
        raise 'Failed to find flock keeper!' unless keeper_node
        DCell.start(
          :node => node.name,
          :addr => "tcp://#{bind_addr}:#{node[:flock_of_chefs][:port]}",
          :directory => {
            :id => keeper_node.name,
            :addr => "tcp://#{registry_ip}:#{keeper_node[:flock_of_chefs][:port]}"
          }
        )
      end
    end
  end
end
