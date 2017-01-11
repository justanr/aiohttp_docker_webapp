====================================
aiohttp web service parent container
====================================

This is a parent container to build aiohttp/gunicorn based web services from.

-----
About
-----

The usual docker reasoning is to provide one process per container, however this one breaks
from that to provide nginx and gunicorn in one service to serve as a logical unit instead of
breaking them up into separate containers.

The reasoning here is if the web service provides static files as well as generated code,
the files aren't oddly broken up into multiple containers that will be more difficult to
orchestrate. This also allows terminating SSL at the nginx process before passing it to nginx.


However, despite nginx and a supervisord setup being provided here, you are not required to use
them if this is only to be an API server that sits behind a container that handles proxying. Simply
remove nginx and the supervisord setup for it in a child script.

--------
Provides
--------

* nginx
* supervisord + nginx configuration
* python3.6
* venv (at /var/www/venv/)
* aiohttp, gunicorn and uvloop in the venv

-------------
Setup Process
-------------

This container by itself provisions very little, just what's listed in the provides section.
However, there are a variety of ONBUILD hooks provided.

ARG and ENV
===========

* `DEV` build arg flag. This is used to mark a container as a development container, this is 
  passed into the environment as the `DEV` envvar so child containers can use it switch on if
  needed. By default it is set to `0` which means not a development build. Setting this to `1`
  triggers the
  development build hooks in the container.
* The `PYTHONASYNCIODEBUG` envvar is set by default to the value of `$DEV` but can be overridden
  if you do not want asyncio debugging in a development build.
* `PYTHONDONTWRITEBYTECODE` is set by default to `1`, which is my personal preferences leaking in
  here. Override this if you like having `*.pyc` and `__pycache__` generated.

Provisioning
============

Here is the order and filepaths executed during child container provisioning:

1. COPY `./container/files` into `/` -- this is used to set any configuration files such as nginx
   and supervisord
2. COPY `.` into `/app` -- this is the base working directory for the image
3. If it exists, `source /app/bin/setup.sh`
4. Ensure the working directory is `/app` this is important for the last step
5. Install `/app/requirements.txt` into the venv -- this file *must* exist
6. If this is a dev container AND it exists, install `/app/requirements-dev.txt` into the venv
7. If `/app/setup.py` exists, install it with the `-e` and `--no-deps` flags
8. If it exists, `source /app/bin/cleanup.sh`

After that, the entrypoint is set to `/app/bin/entrypoint.sh` and the default command is set
to `python`

The `ENTRYPOINT` instruction does not need to be overridden if your intention is to just provide
a entrypoint commands. If you want to inherit this container's entrypoint, override this and invoke
`/app/bin/entrypoint.sh` from your entrypoint. By default, the entrypoint will
`exec /var/www/venv/bin/python $@` if the entrypoint command is `python` otherwise the provided
command is `exec "$@"`
