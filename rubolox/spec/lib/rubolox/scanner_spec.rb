require "rubolox"
require "minitest/autorun"

describe Rubolox::Scanner do
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

  describe "invalid sequence of tokens" do
    let(:source) { "@" }

    it "outputs errors" do
      original_stderr = $stderr
      io = StringIO.new
      $stderr = io

      begin
        scanner.scan_tokens
        output = io.tap(&:rewind).read
        _(output.to_s).must_equal "[Line 1] Error : Unexpected character @.\n"
      ensure
        $stderr = original_stderr
      end
    end
  end
end
