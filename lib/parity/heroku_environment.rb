require 'parity/backup'
require 'parity/environment'

module Parity
  class HerokuEnvironment < Environment
    def initialize(environment_name, subcommands)
      super environment_name, subcommands
    end

    private

    def restore
      Backup.new(from: arguments.first, to: environment).restore
    end
  end
end
