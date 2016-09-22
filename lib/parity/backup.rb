module Parity
  class Backup
    BLANK_ARGUMENTS = "".freeze
    DATABASE_YML_RELATIVE_PATH = "config/database.yml".freeze
    DEVELOPMENT_ENVIRONMENT_KEY_NAME = "development".freeze
    DATABASE_KEY_NAME = "database".freeze

    def initialize(args)
      @from, @to = args.values_at(:from, :to)
      @additional_args = args[:additional_args] || BLANK_ARGUMENTS
    end

    def restore
      if to == DEVELOPMENT_ENVIRONMENT_KEY_NAME
        restore_to_development
      elsif from == DEVELOPMENT_ENVIRONMENT_KEY_NAME
        restore_from_development
      else
        restore_to_remote_environment
      end
    end

    protected

    attr_reader :additional_args, :from, :to

    private

    def restore_from_development
      if dockerized_app?
        $stdout.puts "Parity does not support restoring backups from a dockerized development"
      else 
        Kernel.system(
          "heroku pg:push #{development_db} DATABASE_URL --remote #{to} "\
            "#{additional_args}",
        )
      end
    end

    def restore_to_development
      download_remote_backup
      wipe_development_database
      restore_from_local_temp_backup
      delete_local_temp_backup
    end

    def wipe_development_database
      if dockerized_app?
        Kernel.system("docker-compose exec db dropdb -U postgres #{development_db}")
        Kernel.system("docker-compose exec db createdb -U postgres #{development_db}")
      else
        Kernel.system("dropdb #{development_db} && createdb #{development_db}")
      end
    end

    def download_remote_backup
      Kernel.system(
        "curl -o tmp/latest.backup \"$(#{from} pg:backups public-url -q)\"",
      )
    end

    def restore_from_local_temp_backup
      command = if dockerized_app?
                  "docker-compose exec db "\
                    "pg_restore -U postgres tmp/latest.backup --verbose --clean --no-acl --no-owner "\
                      "-d #{development_db} #{additional_args}"
                else
                  "pg_restore tmp/latest.backup --verbose --clean --no-acl --no-owner "\
                    "-d #{development_db} #{additional_args}"
                end

      Kernel.system(command)
    end

    def delete_local_temp_backup
      Kernel.system("rm tmp/latest.backup")
    end

    def restore_to_remote_environment
      Kernel.system(
        "heroku pg:backups restore #{backup_from} --remote #{to} "\
          "#{additional_args}",
      )
    end

    def backup_from
      "`#{remote_db_backup_url}` DATABASE"
    end

    def remote_db_backup_url
      "heroku pg:backups public-url --remote #{from}"
    end

    def development_db
      YAML.load(database_yaml_file).
        fetch(DEVELOPMENT_ENVIRONMENT_KEY_NAME).
        fetch(DATABASE_KEY_NAME)
    end

    def database_yaml_file
      IO.read(DATABASE_YML_RELATIVE_PATH)
    end

    def dockerized_app?
      File.exists?("docker-compose.yml")
    end
  end
end
