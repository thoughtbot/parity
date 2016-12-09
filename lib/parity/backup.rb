require "etc"

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
      Kernel.system(
        "heroku pg:push #{development_db} DATABASE_URL --remote #{to} "\
          "#{additional_args}",
      )
    end

    def restore_to_development
      download_remote_backup
      wipe_development_database
      restore_from_local_temp_backup
      delete_local_temp_backup
    end

    def wipe_development_database
      Kernel.system("dropdb #{development_db} && createdb #{development_db}")
    end

    def download_remote_backup
      Kernel.system(
        "curl -o tmp/latest.backup \"$(heroku pg:backups:url --remote #{from})\"",
      )
    end

    def restore_from_local_temp_backup
      Kernel.system(
        "pg_restore tmp/latest.backup --verbose --clean --no-acl --no-owner "\
          "--dbname #{development_db} --jobs #{Etc.nprocessors} "\
          "#{additional_args}",
      )
    end

    def delete_local_temp_backup
      Kernel.system("rm tmp/latest.backup")
    end

    def restore_to_remote_environment
      Kernel.system(
        "heroku pg:backups:restore #{backup_from} --remote #{to} "\
          "#{additional_args}",
      )
    end

    def backup_from
      "`#{remote_db_backup_url}` DATABASE"
    end

    def remote_db_backup_url
      "heroku pg:backups:url --remote #{from}"
    end

    def development_db
      YAML.load(database_yaml_file).
        fetch(DEVELOPMENT_ENVIRONMENT_KEY_NAME).
        fetch(DATABASE_KEY_NAME)
    end

    def database_yaml_file
      IO.read(DATABASE_YML_RELATIVE_PATH)
    end
  end
end
