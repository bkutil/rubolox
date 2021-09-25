module OutputCapture
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.tap(&:rewind).read.to_s
  ensure
    $stdout = original_stdout
  end

  def capture_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.tap(&:rewind).read.to_s
  ensure
    $stderr = original_stderr
  end
end
