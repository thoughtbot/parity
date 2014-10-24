Gem::Specification.new do |spec|
  spec.authors = ["Dan Croak"]

  spec.description = <<-eos
    Devevelopment/staging/production parity is intended to decrease the time
    between a developer writing code and having it deployed, make it possible
    for the same people who wrote the code to deploy it and watch its behavior
    in production, and reduce the number of tools necessary to manage.
  eos

  spec.email = ["dan@thoughtbot.com"]
  spec.executables = ["development", "staging", "production"]
  spec.files = `git ls-files -- lib/* README.md`.split("\n")
  spec.homepage = "https://github.com/croaky/parity"
  spec.license = "MIT"
  spec.name = "parity"
  spec.require_paths = ["lib"]
  spec.summary = "Shell commands for development, staging, and production parity."
  spec.version = "0.3.1"
end
