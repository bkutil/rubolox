module Rubolox
  class LoxClass
    include LoxCallable

    attr_accessor :name, :superclass, :methods

    def initialize(name, superclass, methods)
      @name = name
      @superclass = superclass
      @methods = methods
    end

    def find_method(name)
      return methods[name] if methods.key?(name)

      return superclass.find_method(name) unless superclass.nil?

      nil
    end

    def to_s
      name
    end

    def call(interpreter, arguments)
      instance = LoxInstance.new(self)
      initializer = find_method("init")

      initializer.bind(instance).call(interpreter, arguments) unless initializer.nil?

      instance
    end

    def arity
      initializer = find_method("init")

      return 0 if initializer.nil?

      initializer.arity
    end
  end
end
