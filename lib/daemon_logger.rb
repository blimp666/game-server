class DaemonLogger
  include Singleton
  attr_writer :logger
  
  class NullLogger
    def method_missing(*args, &block)
      p @args
    end
  end
  
  
  def init(params)
    raise TypeError.new(":log_file_path required") unless params[:log_file_path]
    file = File.open(params[:log_file_path], 'a')
    file.sync = true
    self.logger = Logger.new(file)
    logger.level = Logger::DEBUG
    logger.formatter = Logger::Formatter.new
    logger.datetime_format = "%y-%m-%d %H:%M:%S.%L"
  end
  
  def self.init(*params)
    instance.init(*params)
  end

  def logger
    if @logger
      @logger
    else
      warn 'Logger not initialized yet, run init with :log_file_path' 
      NullLogger.new
    end
  end
  
  module Mixins
    
    def log(message, log_type = :info)
      puts "#{Time.now} #{log_type} #{message}"
      DaemonLogger.instance.logger.send(log_type, message)
    end
    
    def log_exception(exception, send_mail = true, additional_info = "")
      message = <<"EOF"
Exception was raised #{exception}
#{additional_info}

BACKTRACE:
#{exception.backtrace.join("\n")}
EOF
      puts "SENDING MAIL" if send_mail
      log(message, :error)
    end
    
    def with_exception_logging
      yield
    rescue => e
      log_exception e, send_mail = true, additional_info = 'WITH EXCEPTION LOGGING CRITICAL ERROR'
      raise e
    end
    
    
  end

end
