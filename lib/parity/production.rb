require 'parity/environment'

module Parity
  class Production < Environment
    def initialize(subcommands)
      @environment = 'production'
      super(subcommands)
    end
  end
end
