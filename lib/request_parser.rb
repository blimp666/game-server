# Парсинг запросов через игровой сокет сервер
# Парсит json комманды
GameServer::RequestParser = Struct.new(:data)
class GameServer::RequestParser

  # ==== Return
  # <GameServer::Request>:: объект команды, которая передана
  # юзером.
  # ==== Raises
  # <GameServer::RequestParser::ParserError>:: в случае если синтакси
  # не верной, это не JSON или это не JSON массив, или первый член
  # json массива не строка
  def parse
    request_array = JSON.parse(data.gsub("\000", ""))
    parser_error('Not Array') unless request_array.is_a?(Array)
    parser_error('No request given') unless request_array[0].is_a?(String)
    GameServer::Request.new(request_array[0], request_array[1, request_array.size])
  rescue JSON::ParserError => e
    parser_error("Bad JSON")
  end


  private

  
  # ==== Description
  # райзит ошибку прасинга с заданным name
  def parser_error(name)
    #puts "PARSER ERROR #{name}"
    raise ParserError.new(name, data)
  end
  
  class ParserError < RuntimeError
    def initialize(name, data)
      super("#{name}\n#{data}")
    end
  end
end
