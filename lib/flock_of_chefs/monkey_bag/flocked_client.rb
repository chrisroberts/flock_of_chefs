module FlockOfChefs
  module FlockedClient
    def flocked_converge(*args)
      result = original_converge(*args)
      DCell.me[:resource_manager].completed_run
      DCell.me[:flock_api].active = false
      result
    end

    class << self
      def included(base)
        base.class_eval do
          alias_method :original_converge, :converge
          alias_method :converge, :flocked_converge
        end
      end
    end
  end
end

Chef::Client.send(:include, FlockOfChefs::FlockedClient)
