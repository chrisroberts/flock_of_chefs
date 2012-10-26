module FlockOfChefs
  module FlockedRunner
    def flocked_init(*args)
      original_initialize(*args)
      if(DCell.me)
        DCell.me[:flock_api].active = true
        DCell.me[:resource_manager].new_run(self)
      end
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

unless(Chef::Runner.ancestors.include?(FlockOfChefs::FlockedRunner))
  Chef::Runner.send(:include, FlockOfChefs::FlockedRunner)
end
