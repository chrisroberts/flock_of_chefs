module FlockOfChefs
  class << self
    def [](name)
      DCell::Node[name]
    end

    def get(key)
      if(me)
        me[key]
      end
    end

    def me
      DCell.me
    end

    def global_chef_lock
      unless(@mutex)
        @mutex = Mutex.new
      end
      if(block_given?)
        @mutex.syncronize do
          yield
        end
      else
        @mutex
      end
    end
  end
end
