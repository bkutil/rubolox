module Rubolox
  class AstPrinter
    include  Expr::Visitor

    def print(expr)
      expr.accept(self)
    end

    def visit_binary_expr(expr)
      parenthesize(expr.operator.lexeme, expr.left, expr.right)
    end

    def visit_grouping_expr(grouping)
      parenthesize("group", grouping.expression)
    end

    def visit_literal_expr(literal)
      return "nil" if literal.value.nil?
      literal.value.to_s
    end

    def visit_unary_expr(unary)
      parenthesize(unary.operator.lexeme, unary.right)
    end

    private

    def parenthesize(name, *exprs)
      "(#{name} #{exprs.map { |e| e.accept(self) }.join(" ")})"
    end
  end
end
