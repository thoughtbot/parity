require 'parity/backup'
require 'parity/environment'

module Parity
  class Staging < Environment
    def initialize(subcommands)
      super 'staging', subcommands
    end

    private

    def restore
      Backup.new(from: arguments.first, to: 'staging').restore
    end
  end
end
