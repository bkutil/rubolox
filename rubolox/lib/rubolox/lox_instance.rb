module Rubolox
  class LoxInstance
    attr_accessor :klass

    def initialize(klass)
      @klass = klass
    end

    def to_s
      "#{klass.name} instance"
    end
  end
end
