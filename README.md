Parity
======

[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

Shell commands for development, staging, and production parity for Heroku apps.

Install
-------

    gem install parity

Or bundle it in your project:

    gem "parity"

[releases]: https://github.com/thoughtbot/parity/releases

Parity requires these command-line programs:

    git
    heroku
    pg_restore

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

 * Note that the `restore` command will use the most recent backup (from _staging_ or _production_). You may first need to create a more recent backup before restoring, to prevent download of a very old backup.

Push your local development database backup up to staging:

    staging restore development

Deploy main to production (note that prior versions of Parity would run
database migrations, that's now better handled using [Heroku release phase]):

    production deploy

[Heroku release phase]: https://devcenter.heroku.com/articles/release-phase

Deploy the current branch to staging:

    staging deploy

_Note that deploys to non-production environments use `git push --force`._

Open a console:

    production console
    staging console
    pr_app 1234 console

Migrate a database and restart the dynos:

    production migrate
    staging migrate
    pr_app 1234 migrate

Tail a log:

    production tail
    staging tail
    pr_app 1234 tail

The scripts also pass through, so you can do anything with them that you can do
with `heroku ______ --remote staging` or `heroku ______ --remote production`:

    watch production ps
    staging open

You can optionally parallelize a DB restore by passing `--parallelize`
as a flag to the `development` or `production` commands:
```
    development restore-from production --parallelize
```

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

Pipelines
---------

If you deploy review applications with Heroku pipelines, run commands against
those applications with the `pr_app` command, followed by the PR number for your
application:

```
pr_app 1234 console
```

This command assumes that your review applications have a name derived from the
name of the application your `staging` Git remote points at.

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

Issues
------
Please fill out our [issues template](.github/issue_template.md) if you are
having problems.

Contributing
------------

Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

Version History
---------------

Please see the [releases page](https://github.com/thoughtbot/parity/releases)
for the version history, along with a description of the changes in each
release.

Releasing
---------

See guidelines in [`RELEASING.md`](RELEASING.md) for details

License
-------

Parity is © 2013 thoughtbot, inc.
It is free software,
and may be redistributed under the terms specified in the [LICENSE] file.

[LICENSE]: LICENSE

<!-- START /templates/footer.md -->
## About thoughtbot

![thoughtbot](https://thoughtbot.com/thoughtbot-logo-for-readmes.svg)

This repo is maintained and funded by thoughtbot, inc.
The names and logos for thoughtbot are trademarks of thoughtbot, inc.

We love open source software!
See [our other projects][community].
We are [available for hire][hire].

[community]: https://thoughtbot.com/community?utm_source=github
[hire]: https://thoughtbot.com/hire-us?utm_source=github


<!-- END /templates/footer.md -->
