require_relative 'rubolox/token'
require_relative 'rubolox/token_type'
require_relative 'rubolox/scanner'
require_relative 'rubolox/expr'
require_relative 'rubolox/stmt'
require_relative 'rubolox/ast_printer'
require_relative 'rubolox/parser'
require_relative 'rubolox/runtime_error'
require_relative 'rubolox/environment'
require_relative 'rubolox/lox_callable'
require_relative 'rubolox/lox_function'
require_relative 'rubolox/lox_class'
require_relative 'rubolox/lox_instance'
require_relative 'rubolox/return'
require_relative 'rubolox/resolver'
require_relative 'rubolox/interpreter'

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
    statements = parser.parse

    # Stop if there was a syntax error.
    return if @had_error

    resolver = Resolver.new(@interpreter)
    resolver.resolve_variables(statements)

    # Stop if there was a resolution error.
    return if @had_error

    @interpreter.interpret(statements)
  end

  def self.error(token_or_line, message)
    # BK: we don't have method overloading, so use a check.
    if (token_or_line.is_a?(Integer))
      report(token_or_line, "", message)
    elsif (token_or_line.type == TokenType::EOF)
      report(token_or_line.line, " at end", message)
    else
      report(token_or_line.line, " at '#{token_or_line.lexeme}'", message)
    end
  end

  def self.runtime_error(error)
    $stderr.puts("#{error.message}\n[line #{error.token.line}]")
    @had_runtime_error = true
  end

  def self.report(line, where, message)
    $stderr.puts("[line #{line}] Error#{where}: #{message}")
    @had_error = true
  end
end
