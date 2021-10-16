module Rubolox
  class LoxClass
    include LoxCallable

    attr_accessor :name

    def initialize(name)
      @name = name
    end

    def to_s
      name
    end

    def call(interpreter, arguments)
      LoxInstance.new(self)
    end

    def arity
      0
    end
  end
end
