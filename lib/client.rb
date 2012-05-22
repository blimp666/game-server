module GameServer::Client


  def receive_request(request)
    find_controller(request.name).new(self, request).run
  rescue Exception => e
    logger.info "\n\n\n\n\n\nCRITICAL SERVER ERROR"
    logger.error e
    logger.error e.backtrace.join("\n")
  end

  def send_line(string)
    logger.info "send_line #{string}\n"
    send_data(string + "\n")
  end

  def send_json(object)
    send_line object.to_json
  end


  def receive_data(data)
    @data ||= ""
    @data += data
    if data =~ /\000\n$/
      all_data = @data
      @data = ""
      all_data.gsub!("\000",'').split(/\n/).each do |string|
        request = GameServer::RequestParser.new(string).parse
        receive_request(request)
      end
    end
  end

  def find_controller(name)
    "#{self.class.name}::#{name.to_s.camelize}Controller".constantize
  rescue NameError
    "#{self.class.name}::NilController".constantize
  end

end
