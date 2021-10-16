module Rubolox
  class LoxClass
    include LoxCallable

    attr_accessor :name, :methods

    def initialize(name, methods)
      @name = name
      @methods = methods
    end

    def find_method(name)
      return methods[name] if methods.key?(name)

      nil
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
