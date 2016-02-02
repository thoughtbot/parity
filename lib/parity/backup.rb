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
      drop_development_database
      pull_remote_database_to_development
    end

    def drop_development_database
      Kernel.system("dropdb #{development_db}")
    end

    def pull_remote_database_to_development
      Kernel.system(
        "heroku pg:pull DATABASE_URL #{development_db} --remote #{from} "\
          "#{additional_args}",
      )
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
      YAML.load(parsed_database_yml).
        fetch(DEVELOPMENT_ENVIRONMENT_KEY_NAME).
        fetch(DATABASE_KEY_NAME)
    end

    def parsed_database_yml
      Dotenv.load
      yaml_file = IO.read(DATABASE_YML_RELATIVE_PATH)
      ERB.new(yaml_file).result
    end
  end
end
