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
    heroku
    pg_restore

On OS X, these programs are installed
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

Or, if `restore-from` reads better to you, it's the same thing:

    development restore-from production
    development restore-from staging

Push your local development database backup up to staging:

    staging restore development

Deploy from master to production
and migrate and restart the dynos if necessary:

    production deploy

Deploy the current branch to staging or a feature branch
and migrate and restart the dynos if necessary:

    staging deploy

_Note that deploys to non-production environments use `git push --force`._

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
```
heroku git:remote -r staging -a your-staging-app
heroku git:remote -r production -a your-production-app
```
* There is a `config/database.yml` file that can be parsed as YAML for
  `['development']['database']`.


Customization
-------------

If you have Heroku environments beyond staging and production (such as a feature
environment for each developer), you can add a [binstub] to the `bin` folder of
your application. Custom environments share behavior with staging: they can be
backed up and can restore from production.

Using feature environments requires including Parity as a gem in your
application's Gemfile.

```ruby
gem "parity"
```

[binstub]: https://github.com/sstephenson/rbenv/wiki/Understanding-binstubs

Here's an example binstub for a 'feature-geoff' environment, hosted at
myapp-feature-geoff.herokuapp.com.

```ruby
#!/usr/bin/env ruby

require "parity"

if ARGV.empty?
  puts Parity::Usage.new
else
  Parity::Environment.new("feature-geoff", ARGV).run
end
```

Contributing
------------

Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

Releasing
---------

See guidelines in [`RELEASING.md`](RELEASING.md) for details

License
-------

Parity is © 2013-2016 thoughtbot, inc.
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
