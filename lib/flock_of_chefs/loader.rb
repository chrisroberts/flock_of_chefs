require 'dcell'

Dir[File.join(File.dirname(__FILE__), '**/*.rb')].each do |flock_file|
  require flock_file
end

# Hook in our report handler
Chef::Config.start_handlers << FlockOfChefs::StartConverge.new
Chef::Config.report_handlers << FlockOfChefs::ConcludeConverge.new

