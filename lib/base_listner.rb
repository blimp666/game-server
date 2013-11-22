# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/daemon_logger'
# Базовый модуль для прослушивания JSON запросов от клиента
module GameServer::BaseListner

  # send_data_semaphore -семафор (mutex) для доступа к коннекшену. если не установлен - то не используется.
  # может устанавливаться в приложении connection.send_data_semaphore = Mutex.new
  # process_semaphore - семафор для обработки
  attr_accessor :send_data_semaphore, :process_semaphore

  MAX_INPUT_BUFFER_SIZE = 128 * 1024

  include DaemonLogger::Mixins

  def initialize(*args)
    super(*args)
    self.input_buffer = ""
    self.process_semaphore = Mutex.new
  end

  def find_controller(request)
    return unless request.name =~ /^[A-Za-z_]+$/
    controller_name = (controllers_classes_root + "::" + request.name.camelize)
    log controller_name
    controller_name.constantize
  rescue NameError
    return
  end

  def send_error(name, comment = "")
    send_line(['error', name, comment].to_json )
  end

  def send_line(string)
    send_data(string + "\000\n" )
  end

  def connection_info
    "CONNECTION"
  end


  def send_json(object)
    #send_line '<?xml version="1.0" encoding="UTF-8"?>' + "\n<message>\n" + object.to_json + "\n</message>\n\000"
    send_line object.to_json
  end

  def send_json_with_marker(marker, object)
    send_json [marker, object]
  end

  def send_data(data)
    log "Data sended to #{connection_info}: " + data#.inspect

    if send_data_semaphore
      send_data_semaphore.synchronize { super(data) }
    else
      super(data)
    end
  end


  def critical_error(e)
    log_exception e
    send_error(e.class.to_s.underscore)
#    close_connection_after_writing
  end


  # В этом буфере хранится начало сообщения от клиента, если оно вдруг разбилось на несколько кусоков данных
  attr_accessor :input_buffer

  # Обработать входящие данные (может быть несклько строк запросов в одном пакете данных)
  def receive_data(data)
    data.gsub!("\000", "")

    complete_message = input_buffer + data
    if complete_message[-1] != "\n"
      self.input_buffer = complete_message
      if input_buffer.size >= MAX_INPUT_BUFFER_SIZE
        self.input_buffer.clear
        raise "OVERFLOW OF INPUT BUFFER #{input_buffer.size}"
      end
      return
    else
      input_buffer.clear
    end

    log "Received from #{connection_info} (size #{complete_message.size}): " + complete_message.inspect
    return if policy_file_request(complete_message)
    complete_message.split("\n").each do |query_string|
      operation = proc { process_semaphore.synchronize{ process_query(query_string) } }
      callback = proc { nil }
      EventMachine.defer(operation, callback)
    end
  rescue => e
    critical_error(e)
  end

  # Обработать один запрос
  def process_query(query_string)
    request = GameServer::RequestParser.new(query_string).parse
    controller = find_controller(request)
    return send_error('unknown_request', request.name) unless controller
    controller.new(self, request, GameServer::ObjectSpace.instance).run
  rescue GameServer::RequestParser::ParserError
    send_error('bad_syntax')
  rescue GameServer::ServerError => e
    send_error("server_error", "#{e.name} #{!(e.comment.empty?) ? ':' + e.comment : ''}")
  rescue GameError => e
    send_error(e.class.to_s.underscore, e.message)
  rescue => e
    critical_error(e)
  end


  def policy_file_request(data)
    if data =~ /^<policy-file-request/
      send_data(File.open(Rails.root + 'config/crossdomain.xml' + "\000").read)
      #close_connection_after_writing
      return true
    end
    return false
  end



end
