module Rubolox
  class LoxFunction
    include LoxCallable

    def initialize(declaration)
      @declaration = declaration
    end

    def call(interpreter, arguments)
      environment = Environment.new(interpreter.globals)

      declaration.params.zip(arguments).each do |param, argument|
        environment.define(param.lexeme, argument)
      end

      interpreter.execute_block(declaration.body, environment)

      nil
    end

    def arity
      declaration.params.size
    end

    def to_s
      "<fn #{declaration.name.lexeme}>"
    end

    private

    attr_accessor :declaration
  end
end
