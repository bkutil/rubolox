require "rubolox"
require "minitest/autorun"
require "support/output_capture"

describe Rubolox::Parser do
  include OutputCapture

  let(:parser) { Rubolox::Parser.new(tokens) }
  let(:tokens) { Rubolox::Scanner.new(source).scan_tokens }

  describe "blocks" do
    describe "empty" do
      let(:source) { "{ }" }

      it "produces the correct AST" do
        block = parser.parse.first
        stmt = block.statements

        _(stmt).must_equal []
      end
    end

    describe "non-empty" do
      let(:source) { "{ var a = 1; }" }

      it "produces the correct AST" do
        block = parser.parse.first
        stmt = block.statements.first

        _(stmt.class).must_equal(Rubolox::Stmt::Var)
      end
    end

    describe "unclosed" do
      let(:source) { "{" }

      it "reports an error" do
        output = capture_stderr { parser.parse }
        _(output.to_s).must_equal "[Line 1] Error at end: Expect '}' after block.\n"
      end
    end
  end

  describe "assignment" do
    let(:source) { "a = 1;" }

    it "produces the correct AST" do
      stmt = parser.parse.first
      expr = stmt.expression

      _(expr.class).must_equal(Rubolox::Expr::Assign)
    end
  end

  describe "unary" do
    let(:source) { "-1;" }

    it "produces the correct AST" do
      stmt = parser.parse.first
      expr = stmt.expression

      _(expr.class).must_equal(Rubolox::Expr::Unary)
      _(expr.operator.type).must_equal(Rubolox::TokenType::MINUS)
      _(expr.right.class).must_equal(Rubolox::Expr::Literal)
      _(expr.right.value).must_equal(1)
    end
  end

  describe "primary expressions" do
    {
      "false" => false,
      "true"  => true
    }.each do |type, value|
      describe type do
        let(:source) { "#{type};" }

        it "produces the correct AST" do
          stmt = parser.parse.first
          expr = stmt.expression

          _(expr.class).must_equal(Rubolox::Expr::Literal)
          _(expr.value).must_equal value
        end
      end
    end

    describe "nil" do
      let(:source) { "nil;" }

      it "produces the correct AST" do
        stmt = parser.parse.first
        expr = stmt.expression

        _(expr.class).must_equal(Rubolox::Expr::Literal)
        _(expr.value).must_be_nil
      end
    end

    describe "strings" do
      let(:source) { '"hello world";' }

      it "produces the correct AST" do
        stmt = parser.parse.first
        expr = stmt.expression

        _(expr.class).must_equal(Rubolox::Expr::Literal)
        _(expr.value).must_equal("hello world")
      end
    end

    describe "invalid" do
      let(:source) { ')' }

      it "reports an error" do
        output = capture_stderr { parser.parse }
        _(output.to_s).must_equal "[Line 1] Error at ')': Expect expression.\n" 
      end

      it "returns nil" do
        capture_stderr do
          _(parser.parse).must_equal([nil])
        end
      end
    end

    describe "variables" do
      describe "declarations" do
        let(:source) { "var a = 1;"; }

        it "produces the correct AST" do
          stmt = parser.parse.first
          _(stmt.class).must_equal(Rubolox::Stmt::Var)
          _(stmt.name.lexeme).must_equal("a")
          _(stmt.initializer.value).must_equal(1.0)
        end
      end

      describe "optional initializer" do
        let(:source) { "var a;"; }

        it "produces the correct AST" do
          stmt = parser.parse.first
          _(stmt.class).must_equal(Rubolox::Stmt::Var)
          _(stmt.name.lexeme).must_equal("a")
          _(stmt.initializer).must_be_nil
        end
      end

      describe "access" do
        let(:source) { "a;"; }

        it "produces the correct AST" do
          stmt = parser.parse.first
          _(stmt.class).must_equal(Rubolox::Stmt::Expression)
          _(stmt.expression.class).must_equal(Rubolox::Expr::Variable)
          _(stmt.expression.name.lexeme).must_equal("a")
        end
      end
    end

    describe "equality" do
      let(:source) { "1 == 1;" }

      it "produces the correct AST" do
        stmt = parser.parse.first
        expr = stmt.expression

        _(expr.class).must_equal(Rubolox::Expr::Binary)
        _(expr.operator.type).must_equal(Rubolox::TokenType::EQUAL_EQUAL)
      end
    end

    describe "groups" do
      describe "unterminated" do
        let(:source) { '(nil' }

        it "reports an error" do
          output = capture_stderr { parser.parse }
          _(output.to_s).must_equal "[Line 1] Error at end: Expect ')' after expression.\n" 
        end

        it "returns nil" do
          capture_stderr do
            _(parser.parse).must_equal([nil])
          end
        end
      end

      let(:source) { '(nil);' }

      it "produces the correct AST" do
        stmt = parser.parse.first
        expr = stmt.expression

        _(expr.class).must_equal(Rubolox::Expr::Grouping)
        _(expr.expression.class).must_equal(Rubolox::Expr::Literal)
        _(expr.expression.value).must_be_nil
      end
    end
  end
end

