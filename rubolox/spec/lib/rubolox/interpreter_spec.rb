require "rubolox"
require "minitest/autorun"
require "support/output_capture"

describe Rubolox::Interpreter do
  include OutputCapture

  let(:ast) { Rubolox::Parser.new(tokens).parse }
  let(:tokens) { Rubolox::Scanner.new(source).scan_tokens }
  let(:interpreter) { Rubolox::Interpreter.new }
  let(:resolver) { Rubolox::Resolver.new(interpreter) }
  let(:output) { capture_stdout { resolver.resolve_variables(ast); interpreter.interpret(ast) } }
  let(:errors) { capture_stderr { resolver.resolve_variables(ast); interpreter.interpret(ast) } }

  describe "classes" do
    describe "parsing" do
      let(:source) do
        <<~SRC
        class DevonshireCream {
          serveOn() {
            return "Scones";
          }
        }

        print DevonshireCream;
        SRC
      end

      it "executes correctly" do
        _(output).must_equal("DevonshireCream\n")
      end
    end

    describe "constructor" do
      let(:source) do
        <<~SRC
        class Bagel {}
        var bagel = Bagel();

        print bagel;
        SRC
      end

      it "executes correctly" do
        _(output).must_equal("Bagel instance\n")
      end

      describe "initialization" do
        let(:source) do
          <<~SRC
            class Bagel {
              init(texture) {
                this.texture = texture;
              }
            }
            var bagel = Bagel("crispy");

            print bagel.texture;
          SRC
        end

        it "executes correctly" do
          _(output).must_equal("crispy\n")
        end

        describe "incorrect number of arguments" do
          let(:source) do
            <<~SRC
              class Bagel {
                init(texture) {
                  this.texture = texture;
                }
              }
              var bagel = Bagel();
            SRC
          end

          it "errors out" do
            _(errors).must_include("Expected 1 arguments, but got 0.\n")
          end
        end
      end
    end

    describe "method lookup" do
      let(:source) do
        <<~SRC
        class Bacon {
          eat() {
            print "Crunch crunch crunch";
          }
        }

        Bacon().eat();
        SRC
      end

      it "executes correctly" do
        _(output).must_equal("Crunch crunch crunch\n")
      end
    end

    describe "getters/setters" do
      let(:source) do
        <<~SRC
        class Bagel {}
        var bagel = Bagel();

        bagel.filling = "cheese";
        print bagel.filling;
        SRC
      end

      it "executes correctly" do
        _(output).must_equal("cheese\n")
      end
    end

    describe "field method shadowing" do
      let(:source) do
        <<~SRC
        class Person {
          sayName() {
            print this.name;
          }
        }

        var jane = Person();
        jane.name = "Jane";

        jane.sayName();
        jane.sayName = "Mary";

        print jane.sayName;
        SRC
      end

      it "gives priority to fields" do
        _(output).must_equal("Jane\nMary\n")
      end
    end

    describe "method binding" do
      describe "this - invalid toplevel" do
        let(:source) { "print this;" }
        let(:errors) { capture_stderr { resolver.resolve_variables(ast) } }

        it "errors out" do
          _(errors).must_equal "[Line 1] Error at 'this': Can't use 'this' outside of a class.\n"
        end
      end

      describe "this - invalid inside function" do
        let(:source) { "fun notAMethod() { print this; }" }

        it "errors out" do
          _(errors).must_equal "[Line 1] Error at 'this': Can't use 'this' outside of a class.\n"
        end
      end

      describe "this - property" do
        let(:source) do
          <<~SRC
          class Egotist {
            speak() {
              print this;
            }
          }

          var method = Egotist().speak;
          method();
          SRC
        end

        it "executes correctly" do
          _(output).must_equal("Egotist instance\n")
        end
      end

      describe "this - nested" do
        let(:source) do
          <<~SRC
          class Thing {
            getCallback() {
              fun localFunction() {
                print this;
              }

              return localFunction;
            }
          }

          var callback = Thing().getCallback();
          callback();
          SRC
        end

        it "executes correctly" do
          _(output).must_equal("Thing instance\n")
        end
      end
    end

    describe "method rebinding" do
      let(:source) do
        <<~SRC
        class Person {
          sayName() {
            print this.name;
          }
        }

        var jane = Person();
        jane.name = "Jane";

        var bill = Person();
        bill.name = "Bill";

        bill.sayName = jane.sayName;
        bill.sayName();
        SRC
      end

      it "executes correctly" do
        _(output).must_equal("Jane\n")
      end
    end
  end

  describe "functions" do
    describe "closures" do
      let(:source) do
        <<~SRC
        var a = "global";

        {
          fun showA() {
            print a;
          }

          showA();

          var a = "block";

          showA();
        }
        SRC
      end

      it "executes correctly" do
        _(output).must_equal("global\nglobal\n")
      end
    end

    describe "local functions" do
      let(:source) do
        <<~SRC
          fun makeCounter() {
            var i = 0;
            fun count() {
              i = i + 1;
              print i;
            }

            return count;
          }

          var counter = makeCounter();
          counter();
          counter();
        SRC
      end

      it "executes correctly" do
        _(output).must_equal("1\n2\n")
      end
    end

    describe "return value" do
      let(:source) do
        <<~SRC
          fun fib(n) {
            if (n <= 1) return n;

            return fib(n - 2) + fib(n - 1);
          }

          for (var i = 0; i < 20; i = i + 1) {
            print fib(i);
          }
        SRC
      end

      it "executes correctly" do
        _(output.split("\n").last).must_equal("4181")
      end
    end

    describe "printing a value" do
      let(:source) do
        <<~SRC
          fun add(a, b) {
            print a + b;
          }

          print add;
        SRC
      end

      it "prints the function name" do
        _(output).must_equal("<fn add>\n")
      end
    end

    describe "invocation" do
      let(:source) do
        <<~SRC
          fun count(n) {
            if (n > 1) count(n - 1);
            print n;
          }

          count(3);
        SRC
      end

      it "executes" do
        _(output).must_equal("1\n2\n3\n")
      end
    end

    describe "native" do
      describe "execution" do
        let(:source) do
          <<~SRC
          var a = clock();
          for (var i = 0; i < 10; i = i + 1) { clock(); }
          print clock() - a;
          SRC
        end

        it "executes" do
          _(output).wont_equal("")
        end
      end

      describe "re-assignment" do
        let(:source) { "print clock; clock = 1; print clock;" }

        it "prints the re-assigned value" do
          _(output).must_equal("<native fn>\n1\n")
        end
      end
    end

    describe "arity checks" do
      let(:source) { "clock(1);" }

      it "errors out" do
        _(errors).must_equal "Expected 0 arguments, but got 1.\n[Line 1]\n"
      end
    end

    describe "not callable" do
      let(:source) { '"totally not a function"();' }

      it "errors out" do
        _(errors).must_equal "Can only call functions and classes.\n[Line 1]\n"
      end
    end
  end

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

    describe "local variable shadowing" do
      let(:source) do
        <<~SRC
          fun bad() {
            var a = "first";
            var a = "second";
          }
        SRC
      end

      it "errors out" do
        _(errors).must_include "Error at 'a': already a variable"
      end
    end
  end

  describe "top level return" do
    let(:source) { 'return "at top level";' }
    let(:errors) { capture_stderr { resolver.resolve_variables(ast); } }

    it "errors out" do
      _(errors).must_include "Can't return from top level code"
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

      describe "For" do
        let(:source) do
          <<~SRC
            var a = 0;
            var temp;

            for (var b = 1; a < 10000; b = temp + b) {
              print a;
              temp = a;
              a = b;
            }
          SRC
        end

        it "prints the correct output" do
          _(output.split("\n").last.to_i).must_equal(6765)
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
