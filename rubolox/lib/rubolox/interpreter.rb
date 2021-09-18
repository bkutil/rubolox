module Rubolox
  class Interpreter < Expr::Visitor
    def visit_literal_expr(literal)
      literal.value
    end
  end
end
