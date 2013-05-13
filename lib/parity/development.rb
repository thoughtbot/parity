require 'parity/backup'
require 'parity/environment'

module Parity
  class Development < Environment
    def initialize(subcommands)
      @environment = 'development'
      super(subcommands)
    end

    private

    def restore
      Backup.new(arguments.first, 'development').restore
    end
  end
end
