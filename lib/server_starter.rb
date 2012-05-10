module GameServer::ServerStarter

  def self.included(base)
    base.extend(ClassMethods)
  end


  
  
  module ClassMethods
  
    def listner(klass)
    
      module_eval %(
        def self.start_server(opts = { })
          opts[:port] ||= 10667
          opts[:host] ||= '172.16.90.1'
          EventMachine::run {
            EventMachine::start_server opts[:host], opts[:port], #{klass}
          }
        end
      )
    end
    
  end


end
