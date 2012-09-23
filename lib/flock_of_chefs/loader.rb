require 'flock_of_chefs/flocked_api'
require 'flock_of_chefs/flocked_chef'
require 'flock_of_chefs/flocked_report'

# Hook in our report handler
Chef::Config.report_handlers << FlockOfChefs::FlockedReport.new

