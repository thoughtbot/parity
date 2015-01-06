#!/bin/bash

set -e

REALPATH=$(readlink $0 || $0)
RELATIVE_DIR=$(dirname $REALPATH)
SELF_DIR=$(cd $(dirname $0) && cd $RELATIVE_DIR && pwd)

exec "$SELF_DIR/../lib/ruby/bin/ruby" "$SELF_DIR/../lib/app/bin/development"
