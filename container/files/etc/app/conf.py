import multiprocessing
import os

bind = ['localhost:8080', '[::1]:8080']
proc_name = 'app'
daemon = False
proxy_protocol = True
proxy_allowed_ips = "*"
forward_allow_ips = "*"

workers = (2 * multiprocessing.cpu_count()) + 1
worker_class = 'aiohttp.worker.GunicornUVLoopWebWorker'
worker_connections = 1000
keepalive = 2
timeout = 30

errorlog = '/var/log/app/error.log'
accesslog = '/var/log/app/access.log'
#access_logformat = ''  # noqa
loglevel = 'info'

for k, v in os.environ.items():
    if k.startswith('GUNICORN_'):
        k = k.split('_', 1)[1].lower()
        locals()[k] = v
