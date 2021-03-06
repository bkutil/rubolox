require "rubolox"
require "minitest/autorun"
require "support/output_capture"

describe Rubolox::Scanner do
  include OutputCapture

  let(:scanner) { Rubolox::Scanner.new(source) }

  describe "empty source" do
    let(:source) { "" }

    it "returns an EOF token" do
      _(scanner.scan_tokens).must_equal [
        Rubolox::Token.new(Rubolox::TokenType::EOF, "", nil, 1)
      ]
    end
  end

  describe "single token" do
    let(:source) { "*" }

    it "returns the correct token" do
      _(scanner.scan_tokens).must_equal [
        Rubolox::Token.new(Rubolox::TokenType::STAR, "*", nil, 1),
        Rubolox::Token.new(Rubolox::TokenType::EOF, "", nil, 1)
      ]
    end
  end

  describe "two letter token" do
    let(:source) { ">=" }

    it "returns the correct token" do
      _(scanner.scan_tokens).must_equal [
        Rubolox::Token.new(Rubolox::TokenType::GREATER_EQUAL, ">=", nil, 1),
        Rubolox::Token.new(Rubolox::TokenType::EOF, "", nil, 1)
      ]
    end
  end

  describe "comments" do
    let(:source) do
      <<~SRC
      // comment
      / *
      SRC
    end

    it "returns correct token" do
      _(scanner.scan_tokens).must_equal [
        Rubolox::Token.new(Rubolox::TokenType::SLASH, "/", nil, 2),
        Rubolox::Token.new(Rubolox::TokenType::STAR, "*", nil, 2),
        Rubolox::Token.new(Rubolox::TokenType::EOF, "", nil, 3)
      ]
    end
  end

  describe "strings" do
    describe "multiline" do
      let(:source) do
        <<~SRC
        "hello
        world"
        SRC
      end

      it "returns correct token" do
        _(scanner.scan_tokens).must_equal [
          Rubolox::Token.new(Rubolox::TokenType::STRING, "\"hello\nworld\"", "hello\nworld", 2),
          Rubolox::Token.new(Rubolox::TokenType::EOF, "", nil, 3)
        ]
      end
    end

    describe "simple" do
      let(:source) do
        <<~SRC
        "hello world"
        SRC
      end

      it "returns correct token" do
        _(scanner.scan_tokens).must_equal [
          Rubolox::Token.new(Rubolox::TokenType::STRING, '"hello world"', "hello world", 1),
          Rubolox::Token.new(Rubolox::TokenType::EOF, "", nil, 2)
        ]
      end
    end

    describe "unterminated" do
      let(:source) do
        <<~SRC
        "hello world
        SRC
      end

      it "reports an error" do
        output = capture_stderr { scanner.scan_tokens }
        _(output.to_s).must_equal "[line 2] Error: Unterminated string.\n"
      end
    end
  end

  describe "numbers" do
    describe "integer" do
      let(:source) { "1234" }

      it "returns correct token" do
        _(scanner.scan_tokens).must_equal [
          Rubolox::Token.new(Rubolox::TokenType::NUMBER, "1234", 1234.0, 1),
          Rubolox::Token.new(Rubolox::TokenType::EOF, "", nil, 1)
        ]
      end
    end

    describe "floats" do
      let(:source) { "1234.0" }

      it "returns correct token" do
        _(scanner.scan_tokens).must_equal [
          Rubolox::Token.new(Rubolox::TokenType::NUMBER, "1234.0", 1234.0, 1),
          Rubolox::Token.new(Rubolox::TokenType::EOF, "", nil, 1)
        ]
      end
    end
  end

  describe "identifiers" do
    let(:source) { "f_o_o_1" }

    it "returns correct token" do
      _(scanner.scan_tokens).must_equal [
        Rubolox::Token.new(Rubolox::TokenType::IDENTIFIER, "f_o_o_1", nil, 1),
        Rubolox::Token.new(Rubolox::TokenType::EOF, "", nil, 1)
      ]
    end
  end

  describe "keywords" do
    let(:source) { "or" }

    it "returns correct token" do
      _(scanner.scan_tokens).must_equal [
        Rubolox::Token.new(Rubolox::TokenType::OR, "or", nil, 1),
        Rubolox::Token.new(Rubolox::TokenType::EOF, "", nil, 1)
      ]
    end
  end

  describe "more complex source" do
    let(:source) { "var foo = 1" }

    it "returns correct tokens" do
      _(scanner.scan_tokens).must_equal [
        Rubolox::Token.new(Rubolox::TokenType::VAR, "var", nil, 1),
        Rubolox::Token.new(Rubolox::TokenType::IDENTIFIER, "foo", nil, 1),
        Rubolox::Token.new(Rubolox::TokenType::EQUAL, "=", nil, 1),
        Rubolox::Token.new(Rubolox::TokenType::NUMBER, "1", 1.0, 1),
        Rubolox::Token.new(Rubolox::TokenType::EOF, "", nil, 1)
      ]
    end
  end

  describe "invalid sequence of tokens" do
    let(:source) { "@" }

    it "outputs errors" do
      output = capture_stderr { scanner.scan_tokens }
      _(output).must_equal "[line 1] Error: Unexpected character.\n"
    end
  end
end
