module OutputCapture
  def capture_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.tap(&:rewind).read.to_s
  ensure
    $stderr = original_stderr
  end
end
