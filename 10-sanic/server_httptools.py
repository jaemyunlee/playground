import asyncio
import logging
import sys

from httptools import HttpRequestParser
from httptools.parser.errors import HttpParserError

SERVER_ADDRESS = ('localhost', 8888)

logging.basicConfig(
    level=logging.DEBUG,
    format='%(name)s: %(message)s',
    stream=sys.stderr
)
log = logging.getLogger('main')

event_loop = asyncio.get_event_loop()


class CustomServer(asyncio.Protocol):
    def connection_made(self, transport):
        self.transport = transport
        self.log = logging.getLogger('custom')
        self.log.debug('connection accepted')

    def data_received(self, data):
        self.log.debug(f'receive {data}')
        parser = HttpRequestParser(self)
        print(data)
        try:
            parser.feed_data(data)
        except HttpParserError:
            self.log.error('Bad Request')

    def connection_lost(self, exc):
        if exc:
            self.log.error(f'Error: {exc}')
        else:
            self.log.debug('closing')
        super().connection_lost(exc)

    def on_url(self, url):
        log.debug(f'url: {url}')

    def on_header(self, name, value):
        log.debug(f'header {name}: {value}')

    def on_headers_complete(self):
        log.debug('parsing headers has completed')

    def on_body(self, body):
        log.debug(f'body: {body}')

    def on_message_complete(self):
        log.debug('parsing message has completed')
        self.response('hello world')

    def response(self, value):
        self.transport.write((
             b'HTTP/1.1 200 OK\r\n'
             b'Content-Length: %b\r\n'
             b'Content-Type: text/plain\r\n'
             b'Connection: keep-alive\r\n\r\n'
             b'%b\r\n') % (str(len(value)).encode(), value.encode())
        )


factory = event_loop.create_server(CustomServer, *SERVER_ADDRESS)
server = event_loop.run_until_complete(factory)
log.debug('server started')

try:
    event_loop.run_forever()
finally:
    log.debug('closing server')
    server.close()
    event_loop.run_until_complete(server.wait_closed())
    log.debug('closing event loop')
    event_loop.close()
    