module Rubolox
  class Resolver
    include Expr::Visitor
    include Stmt::Visitor

    module FunctionType
      FUNCTION = :FUNCTION
      INITIALIZER = :INITIALIZER
      NONE = :NONE
      METHOD = :METHOD
    end

    module ClassType
      CLASS = :CLASS
      NONE = :NONE
      SUBCLASS = :SUBCLASS
    end

    def initialize(interpreter)
      @interpreter = interpreter
      @scopes = []
      @current_function = FunctionType::NONE
      @current_class = ClassType::NONE
    end

    # BK: in the original code, there are three methods with a different
    # signature called 'resolve' in this class. Rather than going w/ is_a?
    # checks, or renaming the private method (or prefixing it with e.g. _), we
    # diverge from the book and use 'resolve_variables' as the public method
    # name.
    def resolve_variables(statements)
      statements.each do |statement|
        resolve(statement)
      end
    end

    def visit_block_stmt(stmt)
      begin_scope
      # BK: list of statements, i.e. call the renamed resolve method.
      resolve_variables(stmt.statements)
      end_scope
      nil
    end

    def visit_class_stmt(stmt)
      enclosing_class = self.current_class
      self.current_class = ClassType::CLASS

      declare(stmt.name)
      define(stmt.name)

      if !stmt.superclass.nil? && stmt.name.lexeme == stmt.superclass.name.lexeme
        Rubolox.error(stmt.superclass.name, "A class can't inherit from itself.")
      end

      if !stmt.superclass.nil?
        self.current_class = ClassType::SUBCLASS
        resolve(stmt.superclass)
      end

      if !stmt.superclass.nil?
        begin_scope
        self.scopes.last["super"] = true
      end

      begin_scope
      self.scopes.last["this"] = true

      stmt.methods.each do |method|
        declaration = FunctionType::METHOD
        if method.name.lexeme == "init"
          declaration = FunctionType::INITIALIZER
        end
        resolve_function(method, declaration)
      end

      end_scope

      end_scope unless stmt.superclass.nil?

      self.current_class = enclosing_class
      nil
    end

    def visit_expression_stmt(stmt)
      resolve(stmt.expression)
      nil
    end

    def visit_function_stmt(stmt)
      declare(stmt.name)
      define(stmt.name)
      resolve_function(stmt, FunctionType::FUNCTION)
      nil
    end

    def visit_if_stmt(stmt)
      resolve(stmt.condition)
      resolve(stmt.then_branch)
      resolve(stmt.else_branch) unless stmt.else_branch.nil?
      nil
    end

    def visit_print_stmt(stmt)
      resolve(stmt.expression)
      nil
    end

    def visit_return_stmt(stmt)
      if self.current_function == FunctionType::NONE
        Rubolox.error(stmt.keyword, "Can't return from top-level code.")
      end
      if !stmt.value.nil?
        if self.current_function == FunctionType::INITIALIZER
          Rubolox.error(stmt.keyword, "Can't return a value from an initializer.")
        end

        resolve(stmt.value)
      end
      nil
    end

    def visit_while_stmt(stmt)
      resolve(stmt.condition)
      resolve(stmt.body)
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

    def visit_binary_expr(expr)
      resolve(expr.left)
      resolve(expr.right)
      nil
    end

    def visit_call_expr(expr)
      resolve(expr.callee)

      expr.arguments.each do |argument|
        resolve(argument)
      end

      nil
    end

    def visit_get_expr(expr)
      resolve(expr.object)
      nil
    end

    def visit_grouping_expr(expr)
      resolve(expr.expression)
      nil
    end

    def visit_literal_expr(expr)
      nil
    end

    def visit_logical_expr(expr)
      resolve(expr.left)
      resolve(expr.right)
      nil
    end

    def visit_set_expr(expr)
      resolve(expr.value)
      resolve(expr.object)
      nil
    end

    def visit_super_expr(expr)
      if self.current_class == ClassType::NONE
        Rubolox.error(expr.keyword, "Can't use 'super' outside of a class.")
      elsif self.current_class != ClassType::SUBCLASS
        Rubolox.error(expr.keyword, "Can't use 'super' in a class with no superclass.")
      end

      resolve_local(expr, expr.keyword)
      nil
    end

    def visit_this_expr(expr)
      if self.current_class == ClassType::NONE
        Rubolox.error(expr.keyword, "Can't use 'this' outside of a class.")
        return nil
      end
      resolve_local(expr, expr.keyword)
      nil
    end

    def visit_unary_expr(expr)
      resolve(expr.right)
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

    attr_accessor :interpreter, :scopes, :current_function, :current_class

    def begin_scope
      self.scopes.push({})
    end

    def end_scope
      self.scopes.pop
    end

    def declare(name)
      return if self.scopes.empty?

      scope = self.scopes.last

      if scope.key?(name.lexeme)
        Rubolox.error(name, "Already a variable with this name in this scope.")
      end

      scope[name.lexeme] = false
    end

    def define(name)
      return if self.scopes.empty?

      self.scopes.last[name.lexeme] = true
    end

    def resolve_local(expr, name)
      (self.scopes.size - 1).downto(0) do |i|
        if self.scopes[i].key?(name.lexeme)
          self.interpreter.resolve(expr, self.scopes.size - 1 - i)
          return
        end
      end
    end

    # BK: without overloading there's one resolve method for both statements
    # and expressions.
    def resolve(stmt_or_expression)
      stmt_or_expression.accept(self)
    end

    def resolve_function(function, type)
      enclosing_function = self.current_function
      self.current_function = type
      begin_scope
      function.params.each do |param|
        declare(param)
        define(param)
      end
      # BK: function body is a list of statements, so we need to call the
      # renamed resolve method.
      resolve_variables(function.body)
      end_scope
      self.current_function = enclosing_function
    end
  end
end
