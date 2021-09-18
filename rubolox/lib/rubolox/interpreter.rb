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
        return -Float(right)
      when TokenType::BANG
        return !is_truthy(right)
      end

      # Unreachable
      nil
    end

    private

    def evaluate(expr)
      expr.accept(self)
    end
  end
end
