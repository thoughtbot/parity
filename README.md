Parity
======

Shell commands for development, staging, and production parity.

Install
-------

    gem install parity

This installs three shell commands:

    development
    staging
    production

Usage
-----

Interact with the development environment:

    development restore production
    development restore staging

Interact with the staging environment:

    staging backup
    staging console
    staging log2viz
    staging migrate
    staging restore production
    staging tail

The script also acts as a pass-through, so you can do anything with it that
you can do with `heroku ______ --remote staging`:

    staging open
    watch staging ps

Interact with the production environment:

    production backup
    production console
    production log2viz
    production migrate
    production tail

The script also acts as a pass-through, so you can do anything with it that
you can do with `heroku ______ --remote production`:

    production open
    watch production ps

Credits
-------

Parity is maintained by Dan Croak. It is free software and may be redistributed
under the terms specified in the LICENSE file.
