#!/bin/bash

set -e

REALPATH=$(readlink $0 || $0)
RELATIVE_DIR=$(dirname $REALPATH)
SELF_DIR=$(cd $(dirname $0) && cd $RELATIVE_DIR/.. && pwd)

# Tell Bundler where the Gemfile and gems are.
export BUNDLE_GEMFILE="$(echo $SELF_DIR)/lib/vendor/Gemfile"
unset BUNDLE_IGNORE_CONFIG

exec "$SELF_DIR/lib/ruby/bin/ruby" -rbundler/setup "$SELF_DIR/lib/app/bin/development" "$@"
