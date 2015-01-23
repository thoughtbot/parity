require 'yaml'

module Parity
  class Backup
    def initialize(args)
      @from, @to = args.values_at(:from, :to)
      @additional_args = args[:additional_args] || ""
    end

    def restore
      if to == 'development'
        restore_to_development
      else
        restore_to_pass_through
      end
    end

    protected

    attr_reader :additional_args, :from, :to

    private

    def restore_to_development
      Kernel.system "#{curl} | #{pg_restore}"
    end

    def curl
      "curl -s `#{db_backup_url}`"
    end

    def pg_restore
      "pg_restore --verbose --clean --no-acl --no-owner -d #{development_db}"
    end

    def restore_to_pass_through
      Kernel.system(
        "heroku pg:backups restore #{backup_from} --remote #{to} "\
          "#{additional_args}"
      )
    end

    def backup_from
      "DATABASE `#{db_backup_url}`"
    end

    def db_backup_url
      "heroku pg:backups public-url --remote #{from}"
    end

    def development_db
      yaml_file = IO.read(Parity.config.database_config_path)
      YAML.load(yaml_file)['development']['database']
    end
  end
end
