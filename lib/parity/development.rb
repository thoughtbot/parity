require 'parity/backup'
require 'parity/environment'

module Parity
  class Development < Environment
    def initialize(subcommands)
      super 'development', subcommands
    end

    private

    def restore
      Backup.new(from: arguments.first, to: 'development').restore
    end
  end
end
