import asyncio
import logging
import sys

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
        body = 'hello world!'.encode()
        self.transport.write((
            b'HTTP/1.1 200 OK\r\n'
            b'Content-Length: %b\r\n'
            b'Content-Type: text/plain\r\n'
            b'Connection: keep-alive\r\n\r\n'
            b'%b\r\n') % (str(len(body)).encode(), body)
        )

    def connection_lost(self, exc):
        if exc:
            self.log.error(f'Error: {exc}')
        else:
            self.log.debug('closing')
        super().connection_lost(exc)


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