module FlockOfChefs
  module FlockedRunner
    def flocked_init(*args)
      original_initialize(*args)
      DCell.me[:flock_api].active = true
      DCell.me[:resource_manager].new_run(self)
    end

    class << self
      def included(base)
        base.class_eval do
          alias_method :original_initialize, :initialize
          alias_method :initialize, :flocked_init
        end
      end
    end
  end
end

Chef::Runner.send(:inclue, FlockOfChefs::FlockedRunner)
