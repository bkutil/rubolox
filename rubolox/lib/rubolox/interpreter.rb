module Rubolox
  class Interpreter
    include Expr::Visitor
    include Stmt::Visitor

    def initialize
      @environment = Environment.new
    end

    def interpret(statements)
      statements.each do |statement|
        execute(statement)
      end
    rescue RuntimeError => error
      Rubolox.runtime_error(error)
    end

    def visit_expression_stmt(stmt)
      evaluate(stmt.expression)
      nil
    end

    def visit_if_stmt(stmt)
      if is_truthy(evaluate(stmt.condition))
        execute(stmt.then_branch)
      else
        execute(stmt.else_branch) unless stmt.else_branch.nil?
      end
      nil
    end

    def visit_print_stmt(stmt)
      value = evaluate(stmt.expression)
      $stdout.puts(stringify(value))
      nil
    end

    def visit_var_stmt(stmt)
      value = nil
      value = evaluate(stmt.initializer) unless stmt.initializer.nil?
      self.environment.define(stmt.name.lexeme, value)
      nil
    end

    def visit_while_stmt(stmt)
      while is_truthy(evaluate(stmt.condition))
        execute(stmt.body)
      end
      nil
    end

    def visit_assign_expr(assign)
      value = evaluate(assign.value)
      environment.assign(assign.name, value)
      value
    end

    def visit_literal_expr(literal)
      literal.value
    end

    def visit_logical_expr(logical)
      left = evaluate(logical.left)

      if (logical.operator.type == TokenType::OR)
        return left if is_truthy(left)
      else
        return left if !is_truthy(left)
      end

      evaluate(logical.right)
    end

    def visit_grouping_expr(grouping)
      evaluate(grouping.expression)
    end

    def visit_unary_expr(unary)
      right = evaluate(unary.right)

      case unary.operator.type
      when TokenType::MINUS
        check_number_operand(unary.operator, right)
        -Float(right)
      when TokenType::BANG
        !is_truthy(right)
      else
        # Unreachable
        nil
      end
    end

    def visit_variable_expr(variable)
      self.environment.get(variable.name)
    end

    def visit_binary_expr(binary)
      left = evaluate(binary.left)
      right = evaluate(binary.right)

      case binary.operator.type
      when TokenType::BANG_EQUAL
        !is_equal(left, right)
      when TokenType::EQUAL_EQUAL
        is_equal(left, right)
      when TokenType::GREATER
        check_number_operands(binary.operator, left, right)
        Float(left) > Float(right)
      when TokenType::GREATER_EQUAL
        check_number_operands(binary.operator, left, right)
        Float(left) >= Float(right)
      when TokenType::LESS
        check_number_operands(binary.operator, left, right)
        Float(left) < Float(right)
      when TokenType::LESS_EQUAL
        check_number_operands(binary.operator, left, right)
        Float(left) <= Float(right)
      when TokenType::MINUS
        check_number_operands(binary.operator, left, right)
        Float(left) - Float(right)
      when TokenType::PLUS
        # BK: Ruby doesn't distinguish between native types and their object
        # counterparts, so this looks a little awkward.
        if left.is_a?(Float) && right.is_a?(Float)
          Float(left) + Float(right)
        elsif left.is_a?(String) && right.is_a?(String)
          String(left) + String(right)
        else
          raise RuntimeError.new(binary.operator, "Operands must be two numbers or two strings.")
        end
      when TokenType::SLASH
        check_number_operands(binary.operator, left, right)
        Float(left) / Float(right)
      when TokenType::STAR
        check_number_operands(binary.operator, left, right)
        Float(left) * Float(right)
      else
        nil
      end
    end

    def visit_call_expr(call)
      callee = evaluate(call.callee)

      arguments = []

      call.arguments.each do |argument|
        arguments << evaluate(argument)
      end

      function = callee
      function.call(self, arguments)
    end

    def visit_block_stmt(block)
      execute_block(block.statements, Environment.new(environment))
      nil
    end

    private

    attr_accessor :environment

    def stringify(object)
      return "nil" if object.nil?

      if object.is_a?(Float)
        text = object.to_s
        text = text[0...-2] if text.end_with?(".0")
        return text
      end

      object.to_s
    end

    def check_number_operand(operator, operand)
      return if operand.is_a?(Float)
      raise RuntimeError.new(operator, "Operand must be a number.")
    end

    def check_number_operands(operator, left, right)
      return if left.is_a?(Float) && right.is_a?(Float)
      raise RuntimeError.new(operator, "Operands must be numbers.")
    end

    def is_truthy(object)
      # BK: even though Lox's truthy set is the same as Ruby's, let's keep the
      # code close to the original implementation
      return false if object == nil
      return object if object.is_a?(TrueClass) || object.is_a?(FalseClass)

      true
    end

    def is_equal(a, b)
      return true if a.nil? && b.nil?
      return false if a.nil?

      # FIXME: Java equals
      a == b
    end

    def evaluate(expr)
      expr.accept(self)
    end

    def execute(stmt)
      stmt.accept(self)
    end

    def execute_block(statements, environment)
      previous = self.environment

      begin
        self.environment = environment

        statements.each do |statement|
          execute(statement)
        end
      ensure
        self.environment = previous
      end
    end
  end
end
