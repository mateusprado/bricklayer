module RailsLogging
  
  def self.included(klass)
    klass.extend(self)
  end
  
  def logger
    Rails.logger
  end

end
