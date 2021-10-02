module Rubolox
  class Environment
    attr_reader :enclosing

    def initialize(enclosing = nil)
      @values = {}
      @enclosing = enclosing
    end

    def get(name)
      return self.values[name.lexeme] if self.values.key?(name.lexeme)

      return enclosing.get(name) unless enclosing.nil?

      raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
    end

    def assign(name, value)
      if self.values.key?(name.lexeme)
        self.values[name.lexeme] = value
        return
      end

      unless enclosing.nil?
        enclosing.assign(name, value)
        return
      end

      raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
    end

    def define(name, value)
      self.values[name] = value
    end

    private

    attr_reader :values
  end
end
