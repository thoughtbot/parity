module Parity
  class Configuration
    attr_accessor :database_config_path, :heroku_app_basename

    def initialize
      @database_config_path = 'config/database.yml'
    end
  end

  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Configuration.new

    if block_given?
      yield config
    end
  end
end
