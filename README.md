Parity
======

Shell commands for development, staging, and production parity for Heroku apps.

Install
-------

    gem install parity

This installs three shell commands:

    development
    staging
    production

Your development machine will also need these command-line programs:

    curl
    heroku
    pg_restore

On a Mac, `curl` is installed by default and the other programs can be installed
with Homebrew:

    brew install heroku-toolbelt
    brew install postgres --no-python

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

Convention
----------

Parity expects:

* A `staging` remote pointing to the staging Heroku app.
* A `production` remote pointing to the production Heroku app.
* There is a `config/database.yml` file that can be parsed as Yaml for
  `['development']['database']`.
* The Heroku apps are named like `app-staging` and `app-production`
  where `app` is equal to `basename $PWD`.

Configuration
-------------

Override some of the conventions:

```ruby
Parity.configure do |config|
  config.database_config_path = 'different/path.yml'
  config.heroku_app_basename = 'different-base-name'
end
```

Contributing
------------

Please see CONTRIBUTING.md for details.

Credits
-------

Parity is maintained by Dan Croak. It is free software and may be redistributed
under the terms specified in the LICENSE file.

[1]: https://blog.heroku.com/archives/2013/3/19/log2viz
