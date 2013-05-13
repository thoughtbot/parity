require 'yaml'

module Parity
  class Backup
    def initialize(from, to)
      @from = from
      @to = to
    end

    def restore
      if to == 'development'
        restore_to_development
      else
        restore_to_pass_through
      end
    end

    private

    attr_reader :from, :to

    def restore_to_development
      system %{
        curl -s `#{db_backup_url}` | \
        pg_restore --verbose --clean --no-acl --no-owner -d #{development_db}
      }
    end

    def restore_to_pass_through
      system %{
        heroku pgbackups:restore DATABASE `#{db_backup_url}` --remote #{to}
      }
    end

    def db_backup_url
      "heroku pgbackups:url --remote #{from}"
    end

    def development_db
      YAML.load(IO.read('config/database.yml'))['development']['database']
    end
  end
end
