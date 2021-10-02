module Rubolox
  class Stmt
    module Visitor
      def visit_block_stmt(stmt)
        raise 'To be implemented'
      end

      def visit_expression_stmt(stmt)
        raise 'To be implemented'
      end

      def visit_print_stmt(stmt)
        raise 'To be implemented'
      end

      def visit_var_stmt(stmt)
        raise 'To be implemented'
      end

    end

    class Block < Stmt
      attr_reader :statements

      def initialize(statements)
        @statements = statements
      end

      def accept(visitor)
        visitor.visit_block_stmt(self)
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

    class Var < Stmt
      attr_reader :name, :initializer

      def initialize(name, initializer)
        @name = name
        @initializer = initializer
      end

      def accept(visitor)
        visitor.visit_var_stmt(self)
      end
    end

    def accept(visitor)
      raise 'To be implemented'
    end
  end
end
