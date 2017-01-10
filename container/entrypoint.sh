#!/bin/bash
set -e
case $1 in
    nginx)
        exec supervisord -n -c /etc/supervisor/supervisord.conf
        ;;
    gunicorn)
        exec /var/www/venv/bin/gunicorn myapp:app -c /etc/app/conf.py
        ;;
    devserver)
        shift;
        exec /var/www/venv/bin/python -m aiohttp.web -H 0.0.0.0 $@ myapp:init_app
        ;;
    python)
        shift
        exec /var/www/venv/bin/python $@
        ;;
    *)
        exec "$@"
        ;;
esac
