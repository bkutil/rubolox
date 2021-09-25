module Rubolox
  class Interpreter < Expr::Visitor
    def interpret(expression)
      value = evaluate(expression)
      $stdout.puts(stringify(value))
    rescue RuntimeError => error
      Rubolox.runtime_error(error)
    end

    def visit_literal_expr(literal)
      literal.value
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

    private

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
  end
end
