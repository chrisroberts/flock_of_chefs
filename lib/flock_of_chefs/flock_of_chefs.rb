module FlockOfChefs
  class << self
    def [](name)
      DCell::Node[name]
    end
  end
end
