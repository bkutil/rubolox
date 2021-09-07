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
        self.start = current
        scan_token
      end

      self.tokens << Token.new(TokenType::EOF, "", nil, line)

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
      when "!"
        add_token(match("=") ? TokenType::BANG_EQUAL : TokenType::BANG)
      when "="
        add_token(match("=") ? TokenType::EQUAL_EQUAL : TokenType::EQUAL)
      when "<"
        add_token(match("=") ? TokenType::LESS_EQUAL : TokenType::LESS)
      when ">"
        add_token(match("=") ? TokenType::GREATER_EQUAL : TokenType::GREATER)
      when "/"
        if match("/")
          advance while peek != "\n" && !is_at_end
        else
          add_token(TokenType::SLASH)
        end
      when " ", "\r", "\t"
        # Ignore whitespace.
      when "\n"
        self.line += 1
      when '"'
        string
      else
        if is_digit(c)
          number
        else
          Rubolox.error(line, "Unexpected character #{c}.")
        end
      end
    end

    def number
      advance while is_digit(peek)

      # Look for a fractional part
      if peek == "." && is_digit(peek_next)
        # Consume the .
        advance

        advance while is_digit(peek)
      end

      add_token(TokenType::NUMBER, Float(source[(start...current)]))
    end

    def string
      while peek != '"' && !is_at_end
        self.line += 1 if peek == "\n"
        advance
      end

      if is_at_end
        Rubolox.error(line, "Unterminated string.")
      end

      advance # The closing ".

      # Trim the surrounding quotes.
      value = source[((start + 1)...(current - 1))]
      add_token(TokenType::STRING, value)
    end

    def match(expected)
      return false if is_at_end
      return false if source[current] != expected

      self.current += 1
    end

    def peek
      return "\0" if is_at_end
      source[current]
    end

    def peek_next
      return "\0" if current + 1 >= source.length
      source[current + 1]
    end

    def is_digit(c)
      c >= "0" && c <= "9"
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
      text = source[(start...current)]
      tokens << Token.new(type, text, literal, line)
    end

    attr_accessor :source, :tokens, :start, :current, :line
  end
end
