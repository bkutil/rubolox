module Rubolox
  class Parser
    ParseError = Class.new(StandardError)

    def initialize(tokens)
      @tokens = tokens
      @current = 0
    end

    private

    def expression
      equality
    end

    def equality
      expr = comparison

      while match(TokenType::BANG_EQUAL, TokenType::EQUAL_EQUAL)
        operator = previous
        right = comparsion
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def comparison
      expr = term

      while match(TokenType::GREATER, TokenType::GREATER_EQUAL, TokenType::LESS, TokenType::LESS_EQUAL)
        operator = previous
        right = term
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def term
      expr = factor

      while match(TokenType::MINUS, TokenType::PLUS)
        operator = previous
        right = factor
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def factor
      expr = unary

      while match(TokenType::SLASH, TokenType::STAR)
        operator = previous
        right = factor
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def unary
      if match(TokenType::BANG, TokenType::MINUS)
        operator = preious
        right = unary
        return Expr::Unary.new(operator, right)
      end

      primary
    end

    def primary
      return Expr::Literal.new(false) if match(TokenType::FALSE)
      return Expr::Literal.new(true) if match(TokenType::TRUE)
      return Expr::Literal.new(nil) if match(TokenType::NIL)

      if match(TokenType::NUMBER, TokenType::STRING)
        return Expr::Literal.new(previous.literal)
      end

      if match(TokenType::LEFT_PAREN)
        expr = expression
        consume(Token::RIGHT_PAREN, "Expect ')' after expression.")
        return Expr::Grouping.new(expr)
      end
    end

    def match(*token_types)
      token_types.each do |type|
        if check(type)
          advance
          return true
        end
      end

      false
    end

    def consume(token_type, message)
      return advance if check(type)

      raise error(peek, message)
    end

    def check(type)
      return false if is_at_end
      peek.type == type
    end

    def advance
      self.current += 1 unless is_at_end
    end

    def is_at_end
      peek.type == TokenType::EOF
    end

    def peek
      tokens[current]
    end

    def previous
      tokens[current - 1]
    end

    def error(token, message)
      Rubolox.error(token, message)
      ParseError.new
    end

    attr_accessor :current, :tokens
  end
end
