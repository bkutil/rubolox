require_relative 'rubolox/token_type'
require_relative 'rubolox/scanner'

module Rubolox
  @had_error = false

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
    exit 65 if (@had_error)
  end

  def self.run(source)
    scanner = Scanner.new(source)
    tokens = scanner.scan_tokens

    tokens.each do |token|
      $stdout.puts(token)
    end
  end

  def self.error(line, message)
    report(line, "", message)
  end

  def self.report(line, where, message)
    $stderr.puts("Line #{line}] Error #{where}: #{message}")
    @had_error = true
  end
end
