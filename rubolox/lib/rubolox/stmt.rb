module Rubolox
  class Stmt
    module Visitor
      def visit_expression_stmt(stmt)
        raise 'To be implemented'
      end

      def visit_print_stmt(stmt)
        raise 'To be implemented'
      end

    end

    class Expression < Stmt
      attr_reader :expression

      def initialize(expression)
        @expression = expression
      end

      def accept(visitor)
        visitor.visit_expression_stmt(self)
      end
    end

    class Print < Stmt
      attr_reader :expression

      def initialize(expression)
        @expression = expression
      end

      def accept(visitor)
        visitor.visit_print_stmt(self)
      end
    end

    def accept(visitor)
      raise 'To be implemented'
    end
  end
end
