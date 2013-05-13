module Parity
  class Environment
    def initialize(subcommands)
      @subcommand = subcommands[0]
      @arguments = subcommands[1..-1]
    end

    def run
      if self.class.private_method_defined?(subcommand)
        send(subcommand)
      else
        system "heroku #{pass_through} --remote #{environment}"
      end
    end

    private

    attr_reader :environment, :subcommand, :arguments

    def backup
      system "heroku pgbackups:capture --expire --remote #{environment}"
    end

    def console
      system "heroku run console --remote #{environment}"
    end

    def log2viz
      system "open https://log2viz.herokuapp.com/app/#{heroku_app_name}"
    end

    def migrate
      system %{
        heroku run rake db:migrate --remote #{environment} &&
        heroku restart --remote #{environment}
      }
    end

    def tail
      system "heroku logs --tail --remote #{environment}"
    end

    def heroku_app_name
      [app_name, environment].join('-')
    end

    def app_name
      Dir.pwd.split('/').last
    end

    def pass_through
      [subcommand, arguments].join(' ')
    end
  end
end
