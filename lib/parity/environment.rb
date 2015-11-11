require "parity/backup"

module Parity
  class Environment
    def initialize(environment, subcommands)
      self.environment = environment
      self.subcommand = subcommands[0]
      self.arguments = subcommands[1..-1]
    end

    def run
      run_command || false
    end

    private

    PROTECTED_ENVIRONMENTS = %w(development production)

    attr_accessor :environment, :subcommand, :arguments

    def run_command
      if subcommand == "redis-cli"
        redis_cli
      elsif self.class.private_method_defined?(subcommand)
        send(subcommand)
      else
        run_via_cli
      end
    end

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
      skip_migrations = !run_migrations?

      if deploy_to_heroku
        skip_migrations || migrate
      end
    end

    def deploy_to_heroku
      if production?
        Kernel.system("git push production master")
      else
        Kernel.system(
          "git push #{environment} HEAD:master --force",
        )
      end
    end

    def restore
      if production?
        $stdout.puts "Parity does not support restoring backups into your "\
          "production environment."
      else
        Backup.new(
          from: arguments.first,
          to: environment,
          additional_args: additional_restore_arguments,
        ).restore
      end
    end

    def production?
      environment == "production"
    end

    def additional_restore_arguments
      (arguments.drop(1) + [restore_confirmation_argument]).
        compact.
        join(" ")
    end

    def restore_confirmation_argument
      unless PROTECTED_ENVIRONMENTS.include?(environment)
        "--confirm #{heroku_app_name}"
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

    def run_migrations?
      rails_app? && pending_migrations?
    end

    def rails_app?
      Kernel.system("command -v rake && rake -n db:migrate")
    end

    def pending_migrations?
      !Kernel.system(%{
        git fetch #{environment} &&
        git diff --quiet #{environment}/master..master -- db/migrate
      })
    end
  end
end
