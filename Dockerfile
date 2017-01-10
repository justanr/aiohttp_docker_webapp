FROM python:3.6.0-slim
MAINTAINER alecreiter@gmail.com
ARG DEV=0
ENV PYTHONASYNCIODEBUG=$DEV PYTHONDONTWRITEBYTECODE=1 TERM=xterm
COPY ./container/files /
RUN mkdir -p /var/www/venv/ /var/log/app/
RUN python -m venv /var/www/venv/
RUN /var/www/venv/bin/pip install aiohttp==1.2.0 uvloop==0.7.2 gunicorn==19.6.0
RUN apt-get update && apt-get install -y --fix-missing nginx supervisor apt-utils less
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN echo "source /var/www/venv/bin/activate" >> ~/.bashrc
COPY . /app
RUN if [ -f /app/setup.sh ]; then . /app/setup.sh; fi;
WORKDIR /app
RUN /var/www/venv/bin/pip install -r requirements.txt
RUN if [ "$DEV" -eq "1" ]; then /var/www/venv/bin/pip install -r requirements-dev.txt; fi;
RUN /var/www/venv/bin/pip install -e . --no-deps
RUN rm /etc/nginx/sites-enabled/default
ENTRYPOINT ["/app/container/entrypoint.sh"]
CMD ["python"]
