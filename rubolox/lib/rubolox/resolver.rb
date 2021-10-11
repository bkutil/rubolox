module Rubolox
  class Resolver
    include Expr::Visitor
    include Stmt::Visitor

    attr_accessor :interpreter

    def initializer(interpreter)
      @interpreter = interpreter
    end
  end
end
