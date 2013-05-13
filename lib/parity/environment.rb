module Parity
  class Environment
    def initialize(subcommands)
      @subcommand = subcommands.first
      @pass_through = subcommands.join(' ')
    end

    def run
      case subcommand
      when 'backup'
        system "heroku pgbackups:capture --expire --remote #{environment}"
      when 'console'
        system "heroku run console --remote #{environment}"
      when 'log2viz'
        system "open https://log2viz.herokuapp.com/app/#{heroku_app_name}"
      when 'migrate'
        system %{
          heroku run rake db:migrate --remote #{environment} &&
          heroku restart --remote #{environment}
        }
      when 'tail'
        system "heroku logs --tail --remote #{environment}"
      else
        system "heroku #{pass_through} --remote #{environment}"
      end
    end

    private

    attr_reader :environment, :pass_through, :subcommand

    def heroku_app_name
      [app_name, environment].join('-')
    end

    def app_name
      Dir.pwd.split('/').last
    end
  end
end
