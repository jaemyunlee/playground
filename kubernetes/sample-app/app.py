import os

import aiohttp
from sanic import Sanic
from sanic.response import json

SERVICE_TYPE = os.getenv('SERVICE_TYPE')


app = Sanic()

def getForwardHeaders(request):
    headers = {}

    incoming_headers = ['x-request-id',
                        'x-b3-traceid',
                        'x-b3-spanid',
                        'x-b3-parentspanid',
                        'x-b3-sampled',
                        'x-b3-flags',
                        'x-ot-span-context'
                        ]

    for ihdr in incoming_headers:
        val = request.headers.get(ihdr)
        if val is not None:
            headers[ihdr] = val

    return headers

@app.listener('before_server_start')
async def init(app, loop):
    app.session = await aiohttp.ClientSession(loop=loop).__aenter__()

@app.listener('before_server_stop')
async def finish(app, loop):
    await app.session.close()

@app.route('/')
async def default(request):

    return json({
        'SERVICE_TYPE': SERVICE_TYPE,
        'SERVICE_HOST': os.getenv(f'SERVICE_{SERVICE_TYPE}_SERVICE_HOST', None),
        'SERVICE_PORT': os.getenv(f'SERVICE_{SERVICE_TYPE}_SERVICE_PORT', None)
    })

@app.route('/service')
async def get(request):
    trace_header = getForwardHeaders(request)

    if SERVICE_TYPE == 'A':
        url = 'http://service-b:8000/service'
    if SERVICE_TYPE == 'B':
        url = 'http://service-c:8000/'
    async with aiohttp.ClientSession() as session:
        async with session.get(url, headers=trace_header) as resp:
            return json(await resp.json())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)