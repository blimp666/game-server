class GameServer::ServerError < RuntimeError
  attr_accessor :name, :comment
  def initialize(name, comment = "")
    self.name = name
    self.comment = comment
    super(name)
  end
end
