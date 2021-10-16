module Rubolox
  class LoxInstance
    attr_accessor :klass, :fields

    def initialize(klass)
      @klass = klass
      @fields = {}
    end

    def get(name)
      return fields[name.lexeme] if fields.key?(name.lexeme)

      method = klass.find_method(name.lexeme)
      return method unless method.nil?

      raise RuntimeError.new(name, "Undefined property '#{name.lexeme}'.")
    end

    def set(name, value)
      fields[name.lexeme] = value
      nil
    end

    def to_s
      "#{klass.name} instance"
    end
  end
end
