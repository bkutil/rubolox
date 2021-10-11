module Rubolox
  class Resolver
    include Expr::Visitor
    include Stmt::Visitor

    def initializer(interpreter)
      @interpreter = interpreter
      @scopes = []
    end

    def resolve(statements)
      statements.each do |statement|
        resolve(statement)
      end
    end

    def visit_block_stmt(stmt)
      begin_scope
      resolve(stmt.statements)
      end_scope
      nil
    end

    private

    def begin_scope
      scopes.push {}
    end

    def end_scope
      scopes.pop
    end

    attr_accessor :interpreter, :scopes

    # BK: without overloading there's one resolve method for both statements
    # and expressions.
    def resolve(stmt_or_expression)
      stmt_or_expression.accept(self)
    end
  end
end
