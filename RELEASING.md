Releasing
=========

1. Update the version in `lib/parity/version.rb`
1. Create a new tag based on the version number
1. Create a GitHub [release] for the latest tag
1. Update the [homebrew formula] to point to the latest GitHub release. Include
   the path and the SHA.

Development Releases
====================

Update the [development release] on the repository page, uploading a tarred,
gzipped collection of files. The Homebrew formula does not require a SHA for a
development build, and will always point to the file if the name remains
consistent.

[homebrew formula]: https://github.com/thoughtbot/homebrew-formulae/blob/master/Formula/parity.rb
[release]: https://github.com/thoughtbot/parity/releases
[development release]: https://github.com/thoughtbot/parity/releases/tag/development
