Parity
======

Shell commands for development, staging, and production parity for Heroku apps.

Install
-------

On OS X, this installs everything you need:

    brew tap thoughtbot/formulae
    brew install parity

On other systems you can:

1. Download the package for your system from the [releases page][releases]
1. Extract the tarball and place it so that `/bin` is in your `PATH`

[releases]: https://github.com/thoughtbot/parity/releases

Parity requires these command-line programs:

    git
    curl
    heroku
    pg_restore

On OS X,
`curl` is installed by default.
The other programs are installed
as Homebrew package dependencies of
the `parity` Homebrew package.

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

Deploy from master, and migrate and restart the dynos if necessary:

    production deploy
    staging deploy

Open a console:

    production console
    staging console

Migrate a database and restart the dynos:

    production migrate
    staging migrate

Tail a log:

    production tail
    staging tail

Use [redis-cli][2] with your `REDIS_URL` add-on:

    production redis-cli
    staging redis-cli

The scripts also pass through, so you can do anything with them that you can do
with `heroku ______ --remote staging` or `heroku ______ --remote production`:

    watch production ps
    staging open

[2]: http://redis.io/commands

Convention
----------

Parity expects:

* A `staging` remote pointing to the staging Heroku app.
* A `production` remote pointing to the production Heroku app.
* There is a `config/database.yml` file that can be parsed as YAML for
  `['development']['database']`.
* The Heroku apps are named like `app-staging` and `app-production`
  where `app` is equal to `basename $PWD`.

Contributing
------------

Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

Releasing
---------

See guidelines in [`RELEASING.md`](RELEASING.md) for details

License
-------

Parity is © 2013-2015 thoughtbot, inc.
It is free software,
and may be redistributed under the terms specified in the [LICENSE] file.

[LICENSE]: LICENSE

About thoughtbot
----------------

![thoughtbot](https://thoughtbot.com/logo.png)

Parity is maintained and funded by thoughtbot, inc.
The names and logos for thoughtbot are trademarks of thoughtbot, inc.

We are passionate about open source software.
See [our other projects][community].
We are [available for hire][hire].

[community]: https://thoughtbot.com/community?utm_source=github
[hire]: https://thoughtbot.com?utm_source=github
