require 'logger'

module Socketry
  
  def self.logger
    @@socketry_logger ||= init_logger
  end
  
  def self.logger=(logger)
    @@socketry_logger = logger
  end
  
  private
  
  def self.init_logger
    logger = Logger.new(STDERR)
    logger.level = Logger::WARN
    logger
  end
  
end
