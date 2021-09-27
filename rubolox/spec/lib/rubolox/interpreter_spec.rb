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
      let(:source) { "print nil;" }

      it "returns the correct value" do
        _(output).must_equal("nil\n")
      end
    end

    describe "ints" do
      let(:source) { "print 1;" }

      it "returns the correct value" do
        _(output).must_equal("1\n")
      end
    end

    describe "floats" do
      let(:source) { "print 1.1234;" }

      it "returns the correct value" do
        _(output).must_equal("1.1234\n")
      end
    end

    describe "strings" do
      let(:source) { 'print "hello world";' }

      it "returns the correct value" do
        _(output).must_equal("hello world\n")
      end
    end
  end

  describe "unary expressions" do
    describe "minus" do
      let(:source) { "print -1;" }

      it "returns the correct value" do
        _(output).must_equal("-1\n")
      end
    end

    describe "bang" do
      let(:source) { "print !!true;" }

      it "returns the correct value" do
        _(output).must_equal("true\n")
      end
    end
  end

  describe "binary expression" do
    let(:source) { "print 1 + 2 * 3 / 4;" }

    it "returns the correct value" do
      _(output).must_equal("2.5\n")
    end
  end

  describe "truthiness" do
    describe "string" do
      let(:source) { 'print !!"hello" == true;' }

      it "returns the correct value" do
        _(output).must_equal("true\n")
      end
    end

    describe "number" do
      let(:source) { 'print !!1 == true;' }

      it "returns the correct value" do
        _(output).must_equal("true\n")
      end
    end

    describe "bool" do
      let(:source) { 'print !!true == true;' }

      it "returns the correct value" do
        _(output).must_equal("true\n")
      end
    end
  end
end
