Parity
======

Shell commands for development, staging, and production parity. Currently works
with Heroku only.

Install
-------

    gem install parity

This installs three shell commands:

    development
    staging
    production

Usage
-----

Backup a database:

    production backup
    staging backup

Restore a production or staging database backup into development:

    development restore production
    development restore staging

Restore a production database backup into staging:

    staging restore production

Open a console:

    production console
    staging console

Open [log2viz][1]:

    production log2viz
    staging log2viz

Migrate a database and restart the dynos:

    production migrate
    staging migrate

Tail a log:

    production tail
    staging tail

The scripts also pass through, so you can do anything with them that you can do
with `heroku ______ --remote staging` or `heroku ______ --remote production`:

    watch production ps
    staging open

Credits
-------

Parity is maintained by Dan Croak. It is free software and may be redistributed
under the terms specified in the LICENSE file.

[1]: https://blog.heroku.com/archives/2013/3/19/log2viz
