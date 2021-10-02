module Rubolox
  class Environment
    def initialize
      @values = {}
    end

    def get(name)
      return self.values[name.lexeme] if self.values.key?(name.lexeme)

      raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
    end

    def define(name, value)
      self.values[name] = value
    end

    private

    attr_reader :values
  end
end
