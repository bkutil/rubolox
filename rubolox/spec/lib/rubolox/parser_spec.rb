require "rubolox"
require "minitest/autorun"

describe Rubolox::Parser do
  let(:parser) { Rubolox::Parser.new(tokens) }
  let(:tokens) { Rubolox::Scanner.new(source).scan_tokens }

  def capture_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.tap(&:rewind).read.to_s
  ensure
    $stderr = original_stderr
  end

  describe "unary" do
    let(:source) { "-1" }

    it "produces the correct AST" do
      expr = parser.parse

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
        let(:source) { type }

        it "produces the correct AST" do
          expr = parser.parse

          _(expr.class).must_equal(Rubolox::Expr::Literal)
          _(expr.value).must_equal value
        end
      end
    end

    describe "nil" do
      let(:source) { "nil" }

      it "produces the correct AST" do
        expr = parser.parse

        _(expr.class).must_equal(Rubolox::Expr::Literal)
        _(expr.value).must_be_nil
      end
    end

    describe "strings" do
      let(:source) { '"hello world"' }

      it "produces the correct AST" do
        expr = parser.parse

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
          _(parser.parse).must_be_nil
        end
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
            _(parser.parse).must_be_nil
          end
        end
      end

      let(:source) { '(nil)' }

      it "produces the correct AST" do
        expr = parser.parse

        _(expr.class).must_equal(Rubolox::Expr::Grouping)
        _(expr.expression.class).must_equal(Rubolox::Expr::Literal)
        _(expr.expression.value).must_be_nil
      end
    end
  end
end

