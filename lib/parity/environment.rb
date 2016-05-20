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

    GIT_REMOTE_SEGMENT_DELIMITER_REGEX = /[\/:]/
    GIT_REMOTE_FILE_EXTENSION_REGEX = /\.git$/
    PROTECTED_ENVIRONMENTS = %w(development production)

    attr_accessor :environment, :subcommand, :arguments

    def run_command
      if self.class.private_method_defined?(methodized_subcommand)
        send(methodized_subcommand)
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

    alias :restore_from :restore

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

    def git_remote
      Git.init.remote(environment).url
    end

    def heroku_app_name
      git_remote.
        split(GIT_REMOTE_SEGMENT_DELIMITER_REGEX).
        last.sub(GIT_REMOTE_FILE_EXTENSION_REGEX, "")
    end

    def run_migrations?
      rails_app? && pending_migrations?
    end

    def rails_app?
      has_rakefile? && has_migrations_folder?
    end

    def has_migrations_folder?
      Pathname.new("db").join("migrate").directory?
    end

    def has_rakefile?
      File.exists?("Rakefile")
    end

    def pending_migrations?
      !Kernel.system(%{
        git fetch #{environment} &&
        git diff --quiet #{environment}/master..master -- db/migrate
      })
    end

    def methodized_subcommand
      subcommand.gsub("-", "_").to_sym
    end
  end
end
