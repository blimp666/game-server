# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/daemon_logger'
# Базовый модуль для прослушивания JSON запросов от клиента
module GameServer::BaseListner

  include DaemonLogger::Mixins

  def find_controller(request)
    return unless request.name =~ /^[A-Za-z_]+$/
    x = (controllers_classes_root + "::" + request.name.camelize)
    log x
    x.constantize
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
    super(data)
  end


  def critical_error(e)
    log_exception e
    send_error(e.class.to_s.underscore)
#    close_connection_after_writing
  end

  # Обработать входящие данные (может быть несклько строк запросов в одном пакете данных)
  def receive_data(data)
    data.gsub!("\000", "")
    log "Received from #{connection_info}: " + data.inspect
    return if policy_file_request(data)
    data.split("\n").each do |query_string|
      process_query(query_string)
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
    send_error(e.class.to_s.underscore)
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
