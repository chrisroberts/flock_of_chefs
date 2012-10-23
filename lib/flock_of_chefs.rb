require 'chef'

if(Chef::Version.new(Chef::VERSION) < Chef::Version.new('10.16.0'))
  raise 'Unsupported version of Chef. 10.16.0 or greater required!'
end

require 'flock_of_chefs/version'
require 'flock_of_chefs/loader'
