module Rubolox
  class LoxInstance
    attr_accessor :klass, :fields

    def initialize(klass)
      @klass = klass
      @fields = {}
    end

    def get(name)
      return fields[name.lexeme] if fields.key?(name.lexeme)

      raise RuntimeError.new(name, "Undefined property '#{name.lexeme}'.")
    end

    def to_s
      "#{klass.name} instance"
    end
  end
end
