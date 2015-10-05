require "parity/backup"

module Parity
  class Environment
    def initialize(environment, subcommands)
      self.environment = environment
      self.subcommand = subcommands[0]
      self.arguments = subcommands[1..-1]
    end

    def run
      if subcommand == "redis-cli"
        redis_cli
      elsif self.class.private_method_defined?(subcommand)
        send(subcommand)
      else
        run_via_cli
      end
    end

    private

    attr_accessor :environment, :subcommand, :arguments

    def open
      run_via_cli
    end

    def run_via_cli
      Kernel.system("heroku", subcommand, *arguments, "--remote", environment)
    end

    def backup
      Kernel.system("heroku pg:backups capture --remote #{environment}")
    end

    def deploy
      if deploy_to_heroku && run_migration?
        migrate
      end
    end

    def deploy_to_heroku
      if environment == "production"
        Kernel.system("git push production master")
      else
        Kernel.system(
          "git push #{environment} HEAD:master --force",
        )
      end
    end

    def restore
      if environment == "production"
        $stdout.puts "Parity does not support restoring backups into your "\
          "production environment."
      else
        Backup.new(
          from: arguments.first,
          to: environment,
          additional_args: arguments.drop(1).join(" ")
        ).restore
      end
    end

    def console
      Kernel.system("heroku run rails console --remote #{environment}")
    end

    def migrate
      Kernel.system(%{
        heroku run rake db:migrate --remote #{environment} &&
        heroku restart --remote #{environment}
      })
    end

    def tail
      Kernel.system(
        "heroku logs --tail #{arguments.join(" ")} --remote #{environment}"
      )
    end

    def redis_cli
      url = URI(raw_redis_url)

      Kernel.system(
        "redis-cli",
        "-h",
        url.host,
        "-p",
        url.port.to_s,
        "-a",
        url.password
      )
    end

    def raw_redis_url
      @redis_to_go_url ||= Open3.capture3(
        "heroku config:get REDIS_URL "\
        "--remote #{environment}"
      )[0].strip
    end

    def heroku_app_name
      [basename, environment].join('-')
    end

    def basename
      Dir.pwd.split("/").last
    end

    def run_migration?
      !Kernel.system(%{
        git fetch #{environment} &&
        git diff --quiet #{environment}/master..master -- db/migrate
      })
    end
  end
end
