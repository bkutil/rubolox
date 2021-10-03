require "rubolox"
require "minitest/autorun"
require "support/output_capture"

describe Rubolox::Interpreter do
  include OutputCapture

  let(:ast) { Rubolox::Parser.new(tokens).parse }
  let(:tokens) { Rubolox::Scanner.new(source).scan_tokens }
  let(:interpreter) { Rubolox::Interpreter.new }
  let(:output) { capture_stdout { interpreter.interpret(ast) } }

  describe "blocks" do
    describe "complex" do
      let(:source) do
        %q(
        var a = "global a";
        var b = "global b";
        var c = "global c";
        {
          var a = "outer a";
          var b = "outer b";
          {
            var a = "inner a";
            print a;
            print b;
            print c;
          }
          print a;
          print b;
          print c;
        }
        print a;
        print b;
        print c;
        )
      end

      it "returns the correct values" do
        _(output).must_equal(
          <<~SRC
          inner a
          outer b
          global c
          outer a
          outer b
          global c
          global a
          global b
          global c
          SRC
        )
      end
    end

    describe "nesting" do
      let(:source) { "var a = 1; { print a; }" }

      it "returns the correct value" do
        _(output).must_equal("1\n")
      end
    end

    describe "variable shadowing" do
      let(:source) { "var a = 1; { var a = 2; print a; } print a;" }

      it "returns the correct value" do
        _(output).must_equal("2\n1\n")
      end
    end
  end

  describe "variables" do
    describe "assignment" do
      let(:source) { "var a; print a = 1;" }

      it "returns the correct value" do
        _(output).must_equal("1\n")
      end
    end

    describe "setting and retrieval" do
      let(:source) { "var a; print a;" }

      it "returns the correct value" do
        _(output).must_equal("nil\n")
      end
    end

    describe "simple variable addition" do
      let(:source) { "var a = 1; var b = 2; print a + b;" }

      it "returns the correct value" do
        _(output).must_equal("3\n")
      end
    end
    describe "redeclaration" do
      let(:source) { "var a = 1; var a = 2; print a;" }

      it "returns the latter value" do
        _(output).must_equal("2\n")
      end
    end
  end

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

    describe "loops" do
      describe "while" do
        let(:source) { "var i = 0; while (i < 3) { print i; i = i + 1; }" }

        it "prints the correct output" do
          _(output).must_equal("0\n1\n2\n")
        end
      end
    end

    describe "conditionals" do
      describe "logical operators" do
        describe "or" do
          describe "if truthy" do
            let(:source) { 'print "hi" or 2;' }

            it "prints the left expression" do
              _(output).must_equal("hi\n")
            end
          end

          describe "if falsey" do
            let(:source) { 'print nil or "yes";' }

            it "prints the right expression" do
              _(output).must_equal("yes\n")
            end
          end
        end

        describe "and" do
          describe "if truthy" do
            let(:source) { 'print "hi" and 2;' }

            it "prints the right expression" do
              _(output).must_equal("2\n")
            end
          end

          describe "if falsey" do
            let(:source) { 'print nil and "yes";' }

            it "prints the left expression" do
              _(output).must_equal("nil\n")
            end
          end
        end
      end

      describe "if" do
        let(:source) { "var a = 1; if (a > 0) { print a; } else { print 0; }" }

        it "prints the correct value" do
          _(output).must_equal("1\n")
        end
      end

      describe "if" do
        let(:source) { "var a = -1; if (a > 0) { print a; } else { print 0; }" }

        it "prints the correct value" do
          _(output).must_equal("0\n")
        end
      end

      describe "conditional else" do
        let(:source) { "var a = 1; if (a > 0) { print a; }" }

        it "prints the correct value" do
          _(output).must_equal("1\n")
        end
      end

      describe "dangling else" do
        let(:source) { "var a = 1; if (a < 0) if (a > 0) print a; else print 0;" }

        it "binds to the nearest if" do
          _(output).wont_equal("0\n")
          _(output).must_equal("")
        end
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
