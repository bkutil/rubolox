class Lox
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
    end
  rescue EOFError => _
    exit 0
  end

  # FIXME: charset?
  def self.run_file(path)
    run(File.read(path))
  end

  def self.run(code)
    puts code
  end
end
