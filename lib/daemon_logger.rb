module DaemonLogger
  def init_logger
    return if @logger
    file = File.open(log_file_path, 'a')
    file.sync = true
    @logger = Logger.new(file)
    @logger.level = Logger::DEBUG
    @logger.formatter = Logger::Formatter.new
    @logger.datetime_format = "%y-%m-%d %H:%M:%S.%L"
  end

  def logger
    init_logger
    @logger
  end

end
