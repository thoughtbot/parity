# Releasing

Parity uses a set of `rake` tasks to create packages and bundles [traveling
ruby][traveling_ruby] to simplify the dependency on Ruby.

Generating packages:
-------------------

Packages can be generated for the following systems:

* OSX `rake package:osx`
* Linux x86 `rake package:linux:x86`
* Linux x86_64 `rake package:linux:x86_64`

You can generate all packages with `rake package:all`

[traveling_ruby]: https://github.com/phusion/traveling-ruby

The packages generated are tarballs of the following directory structure:

    parity-package
    ├── bin # shims
    └── lib
        ├── app # parity's bin and lib directories
        └── ruby # traveling ruby for target system

Releasing a new version
----------------------

1. Update the version in `lib/parity/version.rb`
2. Create a new tag based on the version number
3. Generate packages
4. Create a [release] for the latest tag and attach the packages
5. Update the [homebrew formula] to point to the latest OSX package

[homebrew formula]:
https://github.com/thoughtbot/homebrew-formulae/blob/master/Formula/parity.rb
[release]: https://github.com/croaky/parity/releases
