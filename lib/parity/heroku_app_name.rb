module Parity
  class HerokuAppName
    def initialize(environment)
      @environment = environment
    end

    def to_s
      @heroku_app_name ||= Open3.
        capture3("heroku info --remote #{environment}")[0].
        split("\n")[0].
        gsub(/(\s|=)+/, "")
    end

    private

    attr_reader :environment
  end
end
