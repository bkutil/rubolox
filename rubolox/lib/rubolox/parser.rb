module Rubolox
  class Parser
    ParseError = Class.new(StandardError)

    def initialize(tokens)
      @tokens = tokens
      @current = 0
    end

    def parse
      statements = []
      while !is_at_end
        statements << declaration
      end
      statements
    end

    private

    def expression
      assignment
    end

    def declaration
      return var_declaration if match(TokenType::VAR)

      statement
    rescue ParseError => error
      synchronize
      nil
    end

    def statement
      return for_statement if match(TokenType::FOR)
      return if_statement if match(TokenType::IF)
      return print_statement if match(TokenType::PRINT)
      return while_statement if match(TokenType::WHILE)
      return Stmt::Block.new(block) if match(TokenType::LEFT_BRACE)

      expression_statement
    end

    def for_statement
      consume(TokenType::LEFT_PAREN, "Expect '(' after 'for'.")

      initializer = nil

      if match(TokenType::SEMICOLON)
        initializer = nil
      elsif match(TokenType::VAR)
        initializer = var_declaration
      else
        initializer = expression_statement
      end

      condition = nil
      if !check(TokenType::SEMICOLON)
        condition = expression
      end
      consume(TokenType::SEMICOLON, "Expect ';' after loop condition.")

      increment = nil
      if !check(TokenType::RIGHT_PAREN)
        increment = expression
      end
      consume(TokenType::RIGHT_PAREN, "Expect ')' after for clauses.")

      # BK: desugaring for into while 
      body = statement

      unless increment.nil?
        body = Stmt::Block.new([
          body,
          Stmt::Expression.new(increment)
        ])
      end

      if condition.nil?
        condition = Expr::Literal.new(true)
      end

      body = Stmt::While.new(condition, body)

      unless initializer.nil?
        body = Stmt::Block.new([
          initializer,
          body
        ])
      end

      body
    end

    def if_statement
      consume(TokenType::LEFT_PAREN, "Expect '(' after 'if'.")
      condition = expression
      consume(TokenType::RIGHT_PAREN, "Expect ')' after 'if' condition.")

      then_branch = statement
      else_branch = nil

      if match(TokenType::ELSE)
        else_branch = statement
      end

      Stmt::If.new(condition, then_branch, else_branch)
    end

    def print_statement
      value = expression

      consume(TokenType::SEMICOLON, "Expect ';' after value.")

      Stmt::Print.new(value)
    end

    def var_declaration
      name = consume(TokenType::IDENTIFIER, "Expect variable name.")

      initializer = if match(TokenType::EQUAL)
                      expression
                    end

      consume(TokenType::SEMICOLON, "Expect ';' after variable declaration.")

      Stmt::Var.new(name, initializer)
    end

    def while_statement
      consume(TokenType::LEFT_PAREN, "Expect '(' after 'while'.")
      condition = expression
      consume(TokenType::RIGHT_PAREN, "Expect ')' after condition.")
      body = statement

      Stmt::While.new(condition, body)
    end

    def expression_statement
      value = expression

      consume(TokenType::SEMICOLON, "Expect ';' after expression.")

      Stmt::Expression.new(value)
    end

    def block
      statements = []

      while !check(TokenType::RIGHT_BRACE) && !is_at_end
        statements << declaration
      end

      consume(TokenType::RIGHT_BRACE, "Expect '}' after block.")

      statements
    end

    def assignment
      # BK: 'or' is reserved in Ruby
      expr = or_expression

      if match(TokenType::EQUAL)
        equals = previous
        value = assignment

        if expr.is_a?(Expr::Variable)
          name = expr.name
          return Expr::Assign.new(name, value)
        end

        error(equals, "Invalid assignment target.")
      end

      expr
    end

    def or_expression
      # BK: 'and' is reserved in Ruby
      expr = and_expression

      if match(TokenType::OR)
        operator = previous
        right = and_expression
        expr = Expr::Logical.new(expr, operator, right)
      end

      expr
    end

    def and_expression
      expr = equality

      if match(TokenType::AND)
        operator = previous
        right = equality
        expr = Expr::Logical.new(expr, operator, right)
      end

      expr
    end

    def equality
      expr = comparison

      while match(TokenType::BANG_EQUAL, TokenType::EQUAL_EQUAL)
        operator = previous
        right = comparison
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
        operator = previous
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

      if match(TokenType::IDENTIFIER)
        return Expr::Variable.new(previous)
      end

      if match(TokenType::LEFT_PAREN)
        expr = expression
        consume(TokenType::RIGHT_PAREN, "Expect ')' after expression.")
        return Expr::Grouping.new(expr)
      end

      raise error(peek, "Expect expression.")
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
      return advance if check(token_type)

      raise error(peek, message)
    end

    def check(type)
      return false if is_at_end
      peek.type == type
    end

    def advance
      self.current += 1 unless is_at_end
      previous
    end

    def is_at_end
      peek.type == TokenType::EOF
    end

    def peek
      tokens[self.current]
    end

    def previous
      tokens[self.current - 1]
    end

    def error(token, message)
      Rubolox.error(token, message)
      ParseError.new
    end

    def synchronize
      advance

      while !is_at_end
        return if previous.type == TokenType::SEMICOLON

        # BK: use list inclusion instead of a case
        likely_statement_start = [
          TokenType::CLASS,
          TokenType::RETURN,
          TokenType::FUN,
          TokenType::IF,
          TokenType::PRINT,
          TokenType::RETURN,
          TokenType::VAR,
          TokenType::WHILE
        ]

        return if likely_statement_start.include?(peek.type)

        advance
      end
    end

    attr_accessor :current, :tokens
  end
end
