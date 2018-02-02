require File.expand_path("../lib/parity/version", __FILE__)

Gem::Specification.new do |spec|
  spec.authors = ["Dan Croak", "Geoff Harcourt"]

  spec.description = <<-eos
    Development/staging/production parity makes it easier for
    those who write the code to deploy the code.
  eos

  spec.email = ["ralph@thoughtbot.com"]
  spec.executables = ["development", "staging", "production"]
  spec.files = `git ls-files -- lib/* README.md`.split("\n")
  spec.homepage = "https://github.com/thoughtbot/parity"
  spec.license = "MIT"
  spec.name = "parity"
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.2.0"
  spec.summary = "Shell commands for development, staging, and production parity."
  spec.version = Parity::VERSION
end
