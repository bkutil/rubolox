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

    def visit_var_stmt(stmt)
      declare(stmt.name)
      resolve(stmt.initializer) unless stmt.initializer.nil?
      define(stmt.name)
      nil
    end

    private

    attr_accessor :interpreter, :scopes

    def begin_scope
      scopes.push {}
    end

    def end_scope
      scopes.pop
    end

    def declare(name)
      return if self.scopes.empty?

      scope = self.scopes.first
      scope[name.lexeme] = false
    end

    def define(name)
      return if self.scopes.empty?

      self.scopes.first[name.lexeme] = true
    end

    # BK: without overloading there's one resolve method for both statements
    # and expressions.
    def resolve(stmt_or_expression)
      stmt_or_expression.accept(self)
    end
  end
end
