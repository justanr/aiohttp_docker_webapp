FROM python:3.6.0-slim
MAINTAINER alecreiter@gmail.com

RUN apt-get update && apt-get install -qq --no-install-recommends \
        apt-utils \
        nginx \
        supervisor && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/venv/ /var/log/app/

# the python base image  does create a symlink over python to python3 but lets not take chances
RUN python3.6 -m venv /var/www/venv/
RUN /var/www/venv/bin/pip install \
        aiohttp==1.2.0 \
        uvloop==0.7.2 \
        gunicorn==19.6.0

# we modify nginx.conf, unlink the default site and modify .bashrc before copying files in
# in case any of the copied files actually overwrites these

# without this supvisord will continually boot it and report that the port is already in use
# because the first instance actually came up and is online serving requests
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN rm /etc/nginx/sites-enabled/default

# when entering through bash, automatically activate the container's venv in case we need to
# drop into python while in the terminal
RUN echo "source /var/www/venv/bin/activate" >> ~/.bashrc

# override anything in the file system that we need to, do this after system + python installs
# so that they don't overwrite anything we want to put there this does mean that the provided
# venv might be overwritten but in that case, I'm gonna trust you know what you're doing
COPY ./container/files /
COPY . /app

# the default status is not a development build even if that's probably the most common case
# its better to default to safe rather than to easy
# pass the build arg into the environment incase one of the child setup/clean scripts need it
# if you're using v2 docker-compose, you can set build as an yaml dict and pass args there
ONBUILD ARG DEV=1
ONBUILD ENV DEV $DEV
# define if we should enable debugging in the asyncio loop, by default the same value as
# dev as there are performance implications that we don't want in production builds
ONBUILD ENV PYTHONASYNCIODEBUG=$DEV
# I loathe pyc/__pycache__ but you might like them
ONBUILD ENV PYTHONDONTWRITEBYTECODE=1

# copy everything in the next layer here in the same fashion as this container was initially
# provisioned -- this should be used to overwrite anything that this layer might set as well
# as add files to nginx/supervisord/etc
ONBUILD COPY ./container/files /
ONBUILD COPY . /app

# alright, let's actually do some provisioning of this container
# /app/bin/setup.sh should be used to do any system level provisioning before python
# packages are installed -- e.g. install libxml-dev etc or configure existing libs
ONBUILD RUN if [ -f /app/bin/setup.sh ]; then . /app/bin/setup.sh; fi;

# lets install our actual application now
ONBUILD WORKDIR /app
ONBUILD RUN /var/www/venv/bin/pip install -r requirements.txt
# only install the development if we're doing a dev build AND there are dev dependencies
ONBUILD RUN if [ "$DEV" -eq "1" ] && [ -f requirements-dev.txt ]; then /var/www/venv/bin/pip install -r requirements-dev.txt; fi;
# install with --no-deps as it is the safest option and all dependencies should be satsified
# with requirements.txt and requirements-dev.txt
ONBUILD RUN if [ -f /app/setup.py ]; then /var/www/venv/bin/pip install -e . --no-deps; fi;

# app/bin/cleanup.sh should be used to clean up before we're done provisioning
# remove unused packages, remove now unneeded packages, etc.
ONBUILD RUN if [ -f /app/bin/cleanup.sh ]; then . /app/bin/cleanup.sh; fi;

# default entrypoint is this script and the default command is python
# the script itself can be overwritten without changing the entrypoint location
ONBUILD ENTRYPOINT ["/app/bin/entrypoint.sh"]
ONBUILD CMD ["python"]
