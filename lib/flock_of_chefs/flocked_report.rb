require 'chef/handler'
require 'chef/search/query'

module FlockOfChefs

  class FlockedReport < Chef::Handler
    def flocker(currently_active)
      FlockOfChefs.start_flocking!(node)
      dnode = FlockOfChefs.me
      if(dnode)
        dnode[:flock_api].node = node
        dnode[:flock_api].chef_app = ObjectSpace.each_object(Chef::Application).map.first
        dnode[:flock_api].active = currently_active
        Chef::Log.info 'Node information successfully stored in flock.'
        if(!currently_active && dnode[:resource_manager])
          Chef::Log.info 'Sending delayed notifications to flock'
          all_resources.each do |resource|
            FlockOfChefs.get(:resource_manager).send_notifications(
              resource, resource.action, :delayed
            )
          end
        end
      else
        Chef::Log.warn 'Failed to store node information in flock. No flock connection detected.'
      end
      node.save # always save after handling
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

    def zk_search(node)
      zk_search = 'zk_id:*'
      if(node[:flock_of_chefs][:zk_env])
        zk_search << " AND chef_environment:#{node[:flock_of_chefs][:zk_env]}"
      end
      Array(Chef::Search::Query.new.search(:node, zk_search).first)
    end

    def start_flocking!(node)
      if(node[:flock_of_chefs].nil? || node[:flock_of_chefs][:enabled] != true)
        Chef::Log.error 'Flock of Chefs is not currently enabled. `node[:flock_of_chefs][:enabled] = true` to enable'
      else
        zk_nodes = zk_search(node)
        node[:flock_of_chefs][:zk_nodes] ||= []

        if(zk_nodes.empty?)
          Chef::Log.error 'Failed to locate flock registry (zookeeper nodes)'
          return 
        end
        zk_names = zk_nodes.map(&:name).sort

        if((node[:flock_of_chefs][:zk_nodes] + zk_names).uniq.sort != zk_names || FlockOfChefs.me.nil?)
          connect_to_flock(node, zk_nodes)
          Chef::Log.info 'Connection to flock established!'
          node[:flock_of_chefs][:zk_nodes] = zk_names
        else
          Chef::Log.debug 'Already connected to flock!'
        end
      end

      def connect_to_flock(node, zk_nodes)
        bind_addr = find_flock_bind_addr(node)
        base_hsh = {
          :id => node.name,
          :addr => "tcp://#{bind_addr}:#{node[:flock_of_chefs][:port]}"
        }
        zk_nodes = zk_nodes.map{|zk|
          con = "#{zk[:ipaddress]}:#{zk[:zookeeperd][:config][:client_port]}"
          Chef::Log.info "Flock: Detected zookeeper node: #{zk.inspect} -> #{con}"
          con
        }.join(',')

        require 'dcell/registries/zk_adapter'
        # NOTE: zk gem expects comma delimited list of servers, not a
        # splat like dcells attempts. so for now we just join them up
        # here and send them on
        DCell.start(
          :id => node.name,
          :addr => "tcp://#{bind_addr}:#{node[:flock_of_chefs][:port]}",
          :registry => {
            :adapter => 'zk',
            :servers => [zk_nodes]
          }
        )
        Chef::Log.debug "Currently visible nodes: #{DCell::Node.all}"
      end
    end
  end
end
