require "rubolox"
require "minitest/autorun"
require "support/output_capture"

describe Rubolox::Interpreter do
  include OutputCapture

  let(:ast) { Rubolox::Parser.new(tokens).parse }
  let(:tokens) { Rubolox::Scanner.new(source).scan_tokens }
  let(:interpreter) { Rubolox::Interpreter.new }
  let(:output) { capture_stdout { interpreter.interpret(ast) } }

  describe "literals" do
    describe "nil" do
      let(:source) { "nil;" }

      it "returns the correct value" do
        _(output).must_equal("nil\n")
      end
    end

    describe "ints" do
      let(:source) { "1;" }

      it "returns the correct value" do
        _(output).must_equal("1\n")
      end
    end

    describe "floats" do
      let(:source) { "1.1234;" }

      it "returns the correct value" do
        _(output).must_equal("1.1234\n")
      end
    end

    describe "strings" do
      let(:source) { '"hello world";' }

      it "returns the correct value" do
        _(output).must_equal("hello world\n")
      end
    end
  end

  describe "unary expressions" do
    describe "minus" do
      let(:source) { "-1;" }

      it "returns the correct value" do
        _(output).must_equal("-1\n")
      end
    end

    describe "bang" do
      let(:source) { "!!true;" }

      it "returns the correct value" do
        _(output).must_equal("true\n")
      end
    end
  end

  describe "binary expression" do
    let(:source) { "1 + 2 * 3 / 4;" }

    it "returns the correct value" do
      _(output).must_equal("2.5\n")
    end
  end

  describe "truthiness" do
    describe "string" do
      let(:source) { '!!"hello" == true;' }

      it "returns the correct value" do
        _(output).must_equal("true\n")
      end
    end

    describe "number" do
      let(:source) { '!!1 == true;' }

      it "returns the correct value" do
        _(output).must_equal("true\n")
      end
    end

    describe "bool" do
      let(:source) { '!!true == true;' }

      it "returns the correct value" do
        _(output).must_equal("true\n")
      end
    end
  end
end
