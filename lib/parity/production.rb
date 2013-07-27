require 'parity/environment'

module Parity
  class Production < Environment
    def initialize(subcommands)
      super 'production', subcommands
    end
  end
end
