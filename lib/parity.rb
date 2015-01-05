$LOAD_PATH << File.expand_path("..", __FILE__)

require "parity/version"
require "parity/configuration"
require "parity/environment"
require "parity/usage"
require "open3"
require "uri"

Parity.configure
