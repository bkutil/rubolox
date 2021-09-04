module Rubolox
  Token = Struct.new(:type, :lexeme, :literal, :line) do
    def to_s
      "#{type} #{lexeme} #{literal}"
    end
  end
end
