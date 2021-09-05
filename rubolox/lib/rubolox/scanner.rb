module Rubolox
  class Scanner
    def initialize(source)
      @source = source
      @tokens = []
      @start = 0
      @current = 0
      @line = 1
    end

    def scan_tokens
      while !is_at_end do
        start = current
        scan_token
      end

      tokens << Token.new(TokenType::EOF, "", nil, line)

      tokens
    end

    private

    def scan_token
      c = advance
      case c
      when ")"
        add_token(TokenType::LEFT_PAREN)
      when "("
        add_token(TokenType::RIGHT_PAREN)
      when "{"
        add_token(TokenType::LEFT_BRACE)
      when "}"
        add_token(TokenType::RIGHT_BRACE)
      when ","
        add_token(TokenType::COMMA)
      when "."
        add_token(TokenType::DOT)
      when "-"
        add_token(TokenType::MINUS)
      when "+"
        add_token(TokenType::PLUS)
      when ";"
        add_token(TokenType::SEMICOLON)
      when "*"
        add_token(TokenType::STAR)
      else
        Rubolox.error(line, "Unexpected character #{c}.")
      end
    end

    def is_at_end
      current >= source.length
    end

    def advance
      source[current].tap do
        self.current += 1
      end
    end

    def add_token(type, literal = nil)
      text = source[start, current]
      tokens << Token.new(type, text, literal, line)
    end

    attr_accessor :source, :tokens, :start, :current, :line
  end
end
