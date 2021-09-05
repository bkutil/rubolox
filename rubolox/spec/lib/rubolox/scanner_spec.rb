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
end
