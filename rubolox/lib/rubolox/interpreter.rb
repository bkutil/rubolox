module Rubolox
  class Interpreter < Expr::Visitor
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
        Float(left) > Float(right)
      when TokenType::GREATER_EQUAL
        Float(left) >= Float(right)
      when TokenType::LESS
        Float(left) < Float(right)
      when TokenType::LESS_EQUAL
        Float(left) <= Float(right)
      when TokenType::MINUS
        Float(left) - Float(right)
      when TokenType::PLUS
        # BK: Ruby doesn't distinguish between native types and their object
        # counterparts, so this looks a little awkward.
        if left.is_a?(Float) && right.is_a?(Float)
          Float(left) + Float(right)
        elsif left.is_a?(String) && right.is_a?(String)
          String(left) + String(right)
        end
      when TokenType::SLASH
        Float(left) / Float(right)
      when TokenType::STAR
        Float(left) * Float(right)
      else
        nil
      end
    end

    private

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
