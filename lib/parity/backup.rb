require 'yaml'

module Parity
  class Backup
    def initialize(args)
      @from, @to = args.values_at(:from, :to)
      @additional_args = args[:additional_args] || ""
    end

    def restore
      if to == "development"
        restore_to_development
      elsif from == "development"
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

    def pg_restore
      "pg_restore --verbose --clean --no-acl --no-owner -d #{development_db}"
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
      yaml_file = IO.read("config/database.yml")
      YAML.load(yaml_file)['development']['database']
    end
  end
end
