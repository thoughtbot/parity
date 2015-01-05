set -e

RELATIVE_DIR="`dirname \"$0\"`"
SELF_DIR="`cd \"$RELATIVE_DIR\" && pwd`"

exec "$SELF_DIR/ruby/bin/ruby" "$SELF_DIR/bin/development"
