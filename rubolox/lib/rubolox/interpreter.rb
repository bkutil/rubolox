module Rubolox
  class Interpreter < Expr::Visitor
    def visit_literal_expr(literal)
      literal.value
    end

    def visit_grouping_expr(grouping)
      evaluate(grouping.expression)
    end

    private

    def evaluate(expr)
      expr.accept(self)
    end
  end
end
