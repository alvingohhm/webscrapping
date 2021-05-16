
class LogFile
  def initialize (full_file_path)
    @filename = full_file_path
    File.new(full_file_path, "w")
  end
  def write_header=(content)
    File.open( @filename , 'a') do |file|
      file.puts "*" * 40 + content.upcase + " (" + log_time + ")" + "*" * 40
    end
  end

  def write_section=(content)
    File.open( @filename , 'a') do |file|
      file.puts "//" + "=" * 30 + content + " (" + log_time + ")" + "=" * 30  + "//"
    end
  end

  def write_content=(content)
    File.open( @filename , 'a') do |file|
      file.puts content + " (" + log_time + ")"
    end
  end

  def log_time
    Time.now.strftime('%d %b %Y - %H:%M:%S')
  end
end

# test = LogFile.new(File.join(File.absolute_path('..', File.dirname(__FILE__)), "log1.txt"))
# test.write_header = "welcome to log"
# test.write_section = "mysection"
# test.write_content = "hello"
# test.write_content = "hhhahaha"