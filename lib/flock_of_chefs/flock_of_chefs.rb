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
  end
end
