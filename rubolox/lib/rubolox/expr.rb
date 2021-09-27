module Rubolox
  class Expr
    module Visitor
      def visit_binary_expr(expr)
        raise 'To be implemented'
      end

      def visit_grouping_expr(expr)
        raise 'To be implemented'
      end

      def visit_literal_expr(expr)
        raise 'To be implemented'
      end

      def visit_unary_expr(expr)
        raise 'To be implemented'
      end

      def visit_variable_expr(expr)
        raise 'To be implemented'
      end

    end

    class Binary < Expr
      attr_reader :left, :operator, :right

      def initialize(left, operator, right)
        @left = left
        @operator = operator
        @right = right
      end

      def accept(visitor)
        visitor.visit_binary_expr(self)
      end
    end

    class Grouping < Expr
      attr_reader :expression

      def initialize(expression)
        @expression = expression
      end

      def accept(visitor)
        visitor.visit_grouping_expr(self)
      end
    end

    class Literal < Expr
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def accept(visitor)
        visitor.visit_literal_expr(self)
      end
    end

    class Unary < Expr
      attr_reader :operator, :right

      def initialize(operator, right)
        @operator = operator
        @right = right
      end

      def accept(visitor)
        visitor.visit_unary_expr(self)
      end
    end

    class Variable < Expr
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def accept(visitor)
        visitor.visit_variable_expr(self)
      end
    end

    def accept(visitor)
      raise 'To be implemented'
    end
  end
end
