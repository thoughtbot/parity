module Parity
  class Staging < Environment
    def initialize(subcommands)
      @environment = 'staging'
      super(subcommands)
    end
  end
end
