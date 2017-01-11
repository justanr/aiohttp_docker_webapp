#!/bin/bash
set -e
case $1 in
    python)
        shift
        exec /var/www/venv/bin/python $@
        ;;
    *)
        exec "$@"
        ;;
esac
