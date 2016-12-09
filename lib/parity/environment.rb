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
      Kernel.exec("heroku", subcommand, *arguments, "--remote", environment)
    end

    def backup
      Kernel.system("heroku pg:backups:capture --remote #{environment}")
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
      if production? && !forced?
        $stdout.puts "Parity does not support restoring backups into your "\
          "production environment. Use `--force` to override."
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

    def forced?
      arguments.include?("--force")
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
      Kernel.system(command_for_remote("run rails console"))
    end

    def migrate
      Kernel.system(%{
        #{command_for_remote('run rake db:migrate')} &&
        #{command_for_remote('restart')}
      })
    end

    def tail
      Kernel.system(
        command_for_remote("logs --tail #{arguments.join(' ')}"),
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
      @redis_to_go_url ||= Open3.
        capture3(command_for_remote("config:get REDIS_URL"))[0].
        strip
    end

    def heroku_app_name
      @heroku_app_name ||= Open3.
        capture3(command_for_remote("info"))[0].
        split("\n")[0].
        gsub(/(\s|=)+/, "")
    end

    def command_for_remote(command)
      "heroku #{command} --remote #{environment}"
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
        git diff --quiet #{environment}/master..#{compare_with} -- db/migrate
      })
    end

    def compare_with
      if production?
        "master"
      else
        "HEAD"
      end
    end

    def methodized_subcommand
      subcommand.gsub("-", "_").to_sym
    end
  end
end
