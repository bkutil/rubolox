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

    def visit_function_stmt(stmt)
      declare(stmt.name)
      define(stmt.name)
      resolve_function(stmt)
      nil
    end

    def visit_var_stmt(stmt)
      declare(stmt.name)
      resolve(stmt.initializer) unless stmt.initializer.nil?
      define(stmt.name)
      nil
    end

    def visit_assign_expr(expr)
      resolve(expr.value)
      resolve_local(expr, expr.name)
      nil
    end

    def visit_variable_expr(expr)
      if !self.scopes.empty? && self.scopes.first[expr.name.lexeme] == false
        Rubolox.error(expr.name, "Can't read local variable in its own initializer.")
      end

      resolve_local(expr, expr.name)
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

    def resolve_local(expr, name)
      self.scopes.each_with_index.reverse_each do |scope, i|
        if scope.key?(name.lexeme)
          interpreter.resolve(expr, self.scopes.size - 1 - i)
          return
        end
      end
    end

    # BK: without overloading there's one resolve method for both statements
    # and expressions.
    def resolve(stmt_or_expression)
      stmt_or_expression.accept(self)
    end

    def resolve_function(function)
      begin_scope
      function.params.each do |param|
        declare(param)
        define(param)
      end
      resolve(function.body)
      end_scope
    end
  end
end
