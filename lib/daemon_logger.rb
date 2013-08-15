# -*- coding: utf-8 -*-
require 'net/smtp'
require 'singleton'
require 'logger'

class DaemonLogger
  include Singleton
  attr_writer :logger
  attr_accessor :email_receivers, :smtp_server

  class NullLogger
    def method_missing(*args, &block)
      p @args
    end
  end


  # ==== Params
  # params<Hash>::
  # log_file_path<String>:: куда будет писаться лог
  # email_receivers<Array[String]>:: список получателей сообщений о критических ошибках
  def init(params)
    raise TypeError.new(":log_file_path required") unless params[:log_file_path]
    file = File.open(params[:log_file_path], 'a')
    file.sync = true
    self.logger = Logger.new(file)
    logger.level = Logger::DEBUG
    logger.formatter = Logger::Formatter.new
    logger.datetime_format = "%y-%m-%d %H:%M:%S.%L"
    self.email_receivers = params[:email_receivers].to_a
    self.smtp_server = params[:smtp_server] || 'localhost'
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

  # def send_emails_to_receivers(message)
  #   return if !email_receivers or email_receivers.empty?

  #   Net::SMTP.start(smtp_server) do |smtp|
  #     smtp.send_message message, 'daemon.exceptions@skyburg.com', email_receivers
  #   end
  # rescue => e
  #   log_exception(e, false, "SENDING EXCEPTION EMAIL ERROR")
  # end


  module Mixins

    # FIXME:: DOCUMENTATION
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

#       DaemonLogger.instance.send_emails_to_receivers(message) if send_mail
      log(message, :error)
      ExceptionNotifier::Notifier.notify_exception(exception)
    end


    def with_exception_logging
      yield
    rescue => e
      log_exception e, send_mail = true, additional_info = 'WITH EXCEPTION LOGGING CRITICAL ERROR'
      raise e
    end


  end

  include Mixins
end
