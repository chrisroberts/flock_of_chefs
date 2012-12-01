require 'chef/handler'

module FlockOfChefs

  class FlockedReport < Chef::Handler
    def flocker(currently_active)
      unless(FlockOfChefs.me)
        FlockOfChefs.start_flocking!(node)
      end
      dnode = FlockOfChefs.me
      if(dnode)
        dnode[:flock_api].node = node
        dnode[:flock_api].active = currently_active
        Chef::Log.info 'Node information successfully stored in flock.'
        if(!currently_active && dnode[:resource_manager])
          Chef::Log.info 'Sending delayed notifications to flock'
          all_resources.each do |res|
            FlockOfChefs.get(:resource_manager).send_notifications(
              resource, resource.action, :delayed
            )
          end
        end
      else
        Chef::Log.warn 'Failed to store node information in flock. No flock connection detected.'
      end
    end
  end

  class StartConverge < FlockedReport
    def report
      flocker(true)
    end
  end

  class ConcludeConverge < FlockedReport
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
        node.ipaddress
      end
    end

    def find_flock_registry_addr(node, registry_node)
      if(node[:flock_of_chefs][:registry][:ip_address])
        node[:flock_of_chefs][:registry][:ip_address]
      else
        registry_node.ipaddress
      end
    end

    def start_flocking!(node)
      if(node[:flock_of_chefs].nil? || node[:flock_of_chefs][:enabled] != true)
        Chef::Log.error 'Flock of Chefs is not currently enabled. `node[:flock_of_chefs][:enabled] = true` to enable'
      elsif(FlockOfChefs.me)
        Chef::Log.debug 'Flocking is already enabled'
      else
        zk_search = 'zk_id:*'
        if(node[:flock_of_chefs][:zk_env])
          zk_search << " AND chef_environment:#{node[:flock_of_chefs][:zk_env]}"
        end
        zk_nodes = search(:node, zk_search)

        if(zk_nodes.empty?)
          Chef::Log.error 'Failed to locate flock registry (zookeeper nodes)'
          return 
        end

        bind_addr = find_flock_bind_addr(node)
        DCell.start(
          :node => node.name,
          :addr => "tcp://#{bind_addr}:#{node[:flock_of_chefs][:port]}",
          :registry => {
            :adapter => 'zk',
            :servers => zk_nodes.map{|zk| 
              "tcp://#{zk[:ipaddress]}:#{zk[:zookeeperd][:config][:client_port]}"
            }
          }
        )
      end
    end
  end
end
