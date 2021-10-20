module Rubolox
  class LoxFunction
    include LoxCallable

    def initialize(declaration, closure)
      @closure = closure
      @declaration = declaration
    end

    def bind(instance)
      environment = Environment.new(closure)
      environment.define("this", instance)
      LoxFunction.new(declaration, environment)
    end

    def call(interpreter, arguments)
      environment = Environment.new(closure)

      declaration.params.zip(arguments).each do |param, argument|
        environment.define(param.lexeme, argument)
      end

      begin
        interpreter.execute_block(declaration.body, environment)
      rescue Return => return_value
        return return_value.value
      end

      nil
    end

    def arity
      declaration.params.size
    end

    def to_s
      "<fn #{declaration.name.lexeme}>"
    end

    private

    attr_accessor :declaration, :closure
  end
end
