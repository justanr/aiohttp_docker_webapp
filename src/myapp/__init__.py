from aiohttp import web
import asyncio


async def hello(request):
    return web.Response(text="hello")

app = web.Application(loop=asyncio.get_event_loop())
app.router.add_get('/', hello)


def init_app(argv):
    return app
