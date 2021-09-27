require_relative 'rubolox/token'
require_relative 'rubolox/token_type'
require_relative 'rubolox/scanner'
require_relative 'rubolox/expr'
require_relative 'rubolox/stmt'
require_relative 'rubolox/ast_printer'
require_relative 'rubolox/parser'
require_relative 'rubolox/interpreter'
require_relative 'rubolox/runtime_error'

module Rubolox
  @had_error = false
  @had_runtime_error = false
  @interpreter = Interpreter.new

  def self.main(args)
    if args.size > 1
      $stdout.puts "Usage: rubolox [script]"
      exit 64
    elsif args.size == 1
      run_file(args.first)
    else
      run_prompt
    end
  end

  def self.run_prompt
    loop do
      $stdout.print "> "
      line = $stdin.readline
      run(line)
      @had_error = false
    end
  rescue EOFError => _
    exit 0
  end

  # FIXME: charset?
  def self.run_file(path)
    run(File.read(path))

    # Indicate error in the exit code
    exit 65 if @had_error
    exit 70 if @had_runtime_error
  end

  def self.run(source)
    scanner = Scanner.new(source)
    tokens = scanner.scan_tokens

    parser = Parser.new(tokens)
    expression = parser.parse

    return if @had_error

    @interpreter.interpret(expression)
  end

  def self.error(token_or_line, message)
    # BK: we don't have method overloading, so use a check.
    if (token_or_line.is_a?(Integer))
      report(token_or_line, "", message)
    elsif (token_or_line.type == TokenType::EOF)
      report(token_or_line.line, "at end", message)
    else
      report(token_or_line.line, "at '#{token_or_line.lexeme}'", message)
    end
  end

  def self.runtime_error(error)
    $stderr.puts("#{error.message}\n[Line #{error.token.line}]")
    @had_runtime_error = true
  end

  def self.report(line, where, message)
    $stderr.puts("[Line #{line}] Error #{where}: #{message}")
    @had_error = true
  end
end
