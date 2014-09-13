module Parity
  class Configuration
    attr_accessor \
      :database_config_path,
      :heroku_app_basename,
      :redis_url_env_variable

    def initialize
      @database_config_path = "config/database.yml"
      @redis_url_env_variable = "REDIS_URL"
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
