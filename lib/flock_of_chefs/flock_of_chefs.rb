module FlockOfChefs
  class << self
    def [](name)
      DCell::Node[name]
    end

    def get(key)
      DCell.me[key]
    end

    def me
      DCell.me
    end
  end
end
