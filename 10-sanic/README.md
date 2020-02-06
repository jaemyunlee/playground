# Sanic101 <!-- omit in toc -->

Table of Contents
- [Coroutines](#coroutines)
- [Async/Await](#asyncawait)
- [Synchronous vs Asynchronous](#synchronous-vs-asynchronous)
- [AsyncIO](#asyncio)
  - [Transports and Protocols](#transports-and-protocols)
  - [Handling idle connections](#handling-idle-connections)
- [Sanic](#sanic)
  - [Tansports and Protocols](#tansports-and-protocols)
  - [httptools package](#httptools-package)
  - [Three timeout_handlers](#three-timeouthandlers)
  - [request and response](#request-and-response)
    - [middleware](#middleware)
    - [router](#router)

실습 환경
- MacOS
- Python v3.6
- sanic v19.12.2

## Coroutines

> Coroutines are a special type of function that deliberately yield control over to the caller, but does not end its context in the process, instead maintaining it in an idle state.They benefit from the ability to keep their data throughout their lifetime and, unlike functions, can have several entry points for suspending and resuming execution. [stackabuse 참조](https://stackabuse.com/coroutines-in-python/)

`example_coroutine.py`
```python
def example():
    print("Start")
    try:
        while True:
            value = (yield)
            print(value)
    except GeneratorExit:
        print("Exit")


coroutine = example()
next(coroutine)
coroutine.send("hello")
coroutine.send("world")
coroutine.close()

```

## Async/Await

`example_async_await.py`
```python
class Can:
    def __init__(self, action, target):
        self.action = action
        self.target = target

    def __await__(self):
        yield self.action, self.target


async def example():
    print('hello world!')
    await Can('Pass', 'Son')
    await Can('Shoot', 'Son')

coroutine = example()
result = coroutine.send(None)
print(result)
result = coroutine.send(None)
print(result)
coroutine.close()

```

## Synchronous vs Asynchronous

👍[Artisanal Async Adventures - PyCon APAC 2018](https://www.youtube.com/watch?v=IbwirUn9ubA) 참고 

`server_blocking.py`
```python
import socket
from typing import Tuple


Address = Tuple[str, int]


def handler(client: socket.socket) -> None:
    while True:
        request: bytes = client.recv(100)
        if not request.strip():
            client.close()
            return
        number = int(request)
        client.send(f'response: {number}\n'.encode('ascii'))


def server(address: Address) -> None:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(address)
    sock.listen(5)
    while True:
        client, addr = sock.accept()
        print(f'Connection from {addr}')
        handler(client)


server(('localhost', 3030))

```

`server_async.py`
```python
import select
import socket
from collections import deque
from enum import Enum, auto
from typing import Tuple, TypeVar, Deque, Dict

Address = Tuple[str, int]


async def handler(client: socket.socket) -> None:
    while True:
        request: bytes = await async_recv(client, 100)
        if not request.strip():
            client.close()
            return
        await async_send(client, f'response: helloworld\n'.encode())


async def server(address: Address) -> None:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(address)
    sock.listen(5)
    while True:
        client, addr = await async_accept(sock)
        print(f'Connection from {addr}')
        add_task(handler(client))


class Action(Enum):
    Read = auto()
    Send = auto()


class Can:
    def __init__(self, action: Action, target: socket.socket):
        self.action = action
        self.target = target

    def __await__(self):
        yield self.action, self.target


async def async_accept(sock: socket.socket) -> Tuple[socket.socket, Address]:
    await Can(Action.Read, sock)
    return sock.accept()


async def async_recv(sock: socket.socket, num: int) -> bytes:
    await Can(Action.Read, sock)
    return sock.recv(num)


async def async_send(sock: socket.socket, data: bytes) -> int:
    await Can(Action.Send, sock)
    return sock.send(data)


Task = TypeVar('Task')
TASKS: Deque[Task] = deque()
WAIT_READ: Dict[socket.socket, Task] = {}
WAIT_SEND: Dict[socket.socket, Task] = {}


def add_task(task: Task) -> None:
    TASKS.append(task)


def run() -> None:
    while any([TASKS, WAIT_READ, WAIT_SEND]):
        while not TASKS:
            can_read, can_send, _ = select.select(WAIT_READ, WAIT_SEND, [])
            for sock in can_read:
                add_task(WAIT_READ.pop(sock))
            for sock in can_send:
                add_task(WAIT_SEND.pop(sock))
        current_task = TASKS.popleft()
        try:
            action, target = current_task.send(None)
        except StopIteration:
            continue
        if action is Action.Read:
            WAIT_READ[target] = current_task
        elif action is Action.Send:
            WAIT_SEND[target] = current_task
        else:
            raise ValueError(f'Unexepected action {action}')


add_task(server(('localhost', 3030)))
run()

# windows - IOCP, RIO
# Linux - epoll
# BSD - kqueue
```

## AsyncIO

[AsyncIO document](https://docs.python.org/3.6/library/asyncio-task.html#example-chain-coroutines)를 보면 아래와 같은 예제코드와 Sequence diagram이 있다.

`example_asyncio.py`
```python
import asyncio

async def compute(x, y):
    print("Compute %s + %s ..." % (x, y))
    await asyncio.sleep(1.0)
    return x + y

async def print_sum(x, y):
    result = await compute(x, y)
    print("%s + %s = %s" % (x, y, result))

loop = asyncio.get_event_loop()
loop.run_until_complete(print_sum(1, 2))
loop.close()
```

### Transports and Protocols

`server.py`
```python
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
```
`server.py`를 실행하고 request를 보내면 아래와 같이 응답하는 것을 볼 수 있다.

server side
```bash
$ python server.py
...
custom: connection accepted
custom: receive b'GET / HTTP/1.1\r\nHost: localhost:8888\r\nUser-Agent: curl/7.54.0\r\nAccept: */*\r\n\r\n'
custom: closing
```

client side
```bash
$ curl localhost:8888/
hello world!
```

### Handling idle connections

아래의 코드를 실행하게 되면 60초동안 idle connection이 생긴다.

`create_idle_connection.py`
```python
import socket
import time

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.connect(('localhost', 8888))

time.sleep(60)
```

server에서 timeout으로 이러한 idle connection을 막을 수 있다. `loop.call_later()`로 connection을 맺고 timeout시간 안에 packet을 보내지 않으면 `transport`를 close한다.

`server_timeout.py`
```python
import asyncio
import logging
import sys

SERVER_ADDRESS = ('localhost', 8888)
TIMEOUT = 5

logging.basicConfig(
    level=logging.DEBUG,
    format='%(name)s: %(message)s',
    stream=sys.stderr
)
log = logging.getLogger('main')
event_loop = asyncio.get_event_loop()


class CustomServer(asyncio.Protocol):

    def __init__(self):
        loop = asyncio._get_running_loop()
        self.timeout_handle = loop.call_later(
            TIMEOUT, self._timeout
        )
        self.log = logging.getLogger('custom')

    def connection_made(self, transport):
        self.log.debug('connection accepted')
        self.transport = transport

    def data_received(self, data):
        self.log.debug(f'receive {data}')
        self.timeout_handle.cancel()
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

    def _timeout(self):
        self.transport.close()


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
```

## Sanic

*Stream 경우는 생략*

### Tansports and Protocols

Sanic는 Protocol class를 override해서 사용하고 있다.

`/sanic/blob/master/sanic/server.py`
```python
class HttpProtocol(asyncio.Protocol):
    ...
    def connection_made(self, transport):
    ...
    def connection_lost(self, exc):
    ...
    def data_received(self, data):
    ...

def serve(...):
    ...
    server_coroutine = loop.create_server(
        server,
        host,
        port,
        ssl=ssl,
        reuse_port=reuse_port,
        sock=sock,
        backlog=backlog,
        **asyncio_server_kwargs
    )
```

### httptools package

그리고 Sanic은 python package [httptools](https://github.com/MagicStack/httptools)를 사용하고 있다.

`/sanic/blob/master/sanic/server.py`
```python
...
def data_received(self, data):
    ...
    if self.parser is None:
            assert self.request is None
            self.headers = []
            self.parser = HttpRequestParser(self)

        # requests count
        self.state["requests_count"] = self.state["requests_count"] + 1

        # Parse request chunk or close connection
        try:
            self.parser.feed_data(data)
        except HttpParserError:
            message = "Bad Request"
            if self._debug:
                message += "\n" + traceback.format_exc()
            self.write_error(InvalidUsage(message))

def on_url(self, url):
    ...
def on_header(self, name, value):
    ...
def on_headers_complete(self):
    ...
def on_body(self, body):
    ...
def on_message_complete(self):
    ...
```

간단하게 `httptools`를 사용해서 server.py를 수정해보자.

`server_httptools.py`
```python
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
```

curl로 request를 해보면 parser가 어떻게 callback 함수와 작동되는지를 볼 수 있다.

client
```bash
$ curl -X POST -H "Content-Type: application/json" -d '{"devops":"jaemyun"}' localhost:8888/
```

server
```bash
custom: connection accepted
custom: receive b'POST / HTTP/1.1\r\nHost: localhost:8888\r\nUser-Agent: curl/7.54.0\r\nAccept: */*\r\nContent-Type: application/json\r\nContent-Length: 20\r\n\r\n{"devops":"jaemyun"}'
b'POST / HTTP/1.1\r\nHost: localhost:8888\r\nUser-Agent: curl/7.54.0\r\nAccept: */*\r\nContent-Type: application/json\r\nContent-Length: 20\r\n\r\n{"devops":"jaemyun"}'
main: url: b'/'
main: header b'Host': b'localhost:8888'
main: header b'User-Agent': b'curl/7.54.0'
main: header b'Accept': b'*/*'
main: header b'Content-Type': b'application/json'
main: header b'Content-Length': b'20'
main: parsing headers has completed
main: body: b'{"devops":"jaemyun"}'
main: parsing message has completed
custom: closing
```

### Three timeout_handlers

sanic에서 timeout을 관리하도록 세 가지의 handler가 존재
- _keep_alive_timeout_handler
- _request_timeout_handler
- -response_timeout_handler

1. connection_made 시점:
   ```python
   self._request_timeout_handler = self.loop.call_later(
       self.request_timeout, self.request_timeout_callback
   )
   self._last_request_time = time()
   ```
2. on_headers_complete 시점:
   ```python
   if self._keep_alive_timeout_handler:
        self._keep_alive_timeout_handler.cancel()
        self._keep_alive_timeout_handler = None
   ```
3. on_message_complete 시점:
   ```python
   if self._request_timeout_handler:
        self._request_timeout_handler.cancel()
        self._request_timeout_handler = None
   ```
4. execute_request_handler 시점:
   ```python
   self._response_timeout_handler = self.loop.call_later(
            self.response_timeout, self.response_timeout_callback
        )
   self._last_request_time = time()
   ```
5. write_response 시점:
   ```python
   if self._response_timeout_handler:
        self._response_timeout_handler.cancel()
        self._response_timeout_handler = None

   self._keep_alive_timeout_handler = self.loop.call_later(
        self.keep_alive_timeout, self.keep_alive_timeout_callback
    )
   self._last_response_time = time()
   ```

request_timeout_callback, response_timeout_callback, keep_alive_timeout_callback 모두 다 아래처럼 `_last_request_time`으로 default timeout를 넘었는지 확인한다.

```python
time_elapsed = time() - self._last_request_time
if time_elapsed < self.response_timeout:
    time_left = self.response_timeout - time_elapsed
    self._response_timeout_handler = self.loop.call_later(
        time_left, self.response_timeout_callback
    )
```

다시 정리해보자면 각 default 값에 대해서 다음과 같이 timeout이 발생한다.
- request_timeout=60\
  처음 connection이 맺어지고 data packet를 받아서 message parsing이 완료되는 시점까지 60초안에 완료되어야 한다.
- response_timeout=60\
  message parsing이 완료되고 write_response가 실행될 때까지 60초안에 완료되어야 한다.
- keep_alive_timeout=5\
  write response가 완료되고 다시 data packet을 받아서 header parsing이 완료되는 시점까지 5초안에 완료되어야 한다.

### request and response

`request.py`에 Request class가 존재하고 `on_headers_complete`시점에 Request class의 instance를 만든다.

`sanic/sanic/server.py`
```python
def on_headers_complete(self):
    self.request = self.request_class(
        url_bytes=self.url,
        headers=Header(self.headers),
        version=self.parser.get_http_version(),
        method=self.parser.get_method().decode(),
        transport=self.transport,
        app=self.app,
    )
```

그리고 이제 body부분도 parsing이 완료되면 Request instance에 `body_push` method로 body내용을 추가한다.

`sanic/sanic/server.py`
```python
def on_body(self, body):
    ...
    else:
        self.request.body_push(body)
```

모든 message가 parsing이 완료되면 이제 `execute_request_handler`를 call하고 `request_handler`를 실행하는 Task를 생성한다.

`sanic/sanic/server.py`
```python
def on_message_complete(self):
    ...
    self.execute_request_handler()
```

`sanic/sanic/server.py`
```python
def execute_request_handler(self):
    """
    Invoke the request handler defined by the
    :func:`sanic.app.Sanic.handle_request` method
    :return: None
    """
    self._response_timeout_handler = self.loop.call_later(
        self.response_timeout, self.response_timeout_callback
    )
    self._last_request_time = time()
    self._request_handler_task = self.loop.create_task(
        self.request_handler(
            self.request, self.write_response, self.stream_response
        )
    )
```

`request_handler`는 Request instance를 받아서 callback으로 `write_response`를 호출하게 된다. 최종적으로 `write_response`에서 `transport.write`로 client에 response한다.

`sanic/sanic/server.py`
```python
def write_response(self, response):
    ...
    try:
        keep_alive = self.keep_alive
        self.transport.write(
            response.output(
                self.request.version, keep_alive, self.keep_alive_timeout
            )
        )
    ...
```

이제 `execute_request_handler`를 자세히 봐보자.

```python
self._request_handler_task = self.loop.create_task(
    self.request_handler(
        self.request, self.write_response, self.stream_response
    )
)
```

`request_handler`는 Sanic class를 run할 때 Sanic class의 `handle_request` method로 설정이 된다. `handle_request`를 보면 request쪽 middleware를 통과하고 그다음에 router로 부터 가져온 handler가 실행이 되고 마지막으로 response쪽 middleware를 통과한다음 최종적으로 `write_callback` 함수를 호출한다. 위에서 `execute_request_handler`를 보면 `write_callback`이 `write_response`로 설정된 것을 확인 할 수 있다. `write_response`에서 `transport.write`를 하게 된다.

`sanic/sanic/app.py`
```python
class Sanic:
    ...
    async def handle_request(self, request, write_callback, stream_callback):
        """Take a request from the HTTP Server and return a response object
        to be sent back The HTTP Server only expects a response object, so
        exception handling must be done here
        :param request: HTTP Request object
        :param write_callback: Synchronous response function to be
            called with the response as the only argument
        :param stream_callback: Coroutine that handles streaming a
            StreamingHTTPResponse if produced by the handler.
        :return: Nothing
        """
        # Define `response` var here to remove warnings about
        # allocation before assignment below.
        response = None
        cancelled = False
        name = None
        try:
            # Fetch handler from router
            handler, args, kwargs, uri, name = self.router.get(request)

            # -------------------------------------------- #
            # Request Middleware
            # -------------------------------------------- #
            response = await self._run_request_middleware(
                request, request_name=name
            )
            # No middleware results
            if not response:
                # -------------------------------------------- #
                # Execute Handler
                # -------------------------------------------- #

                request.uri_template = uri
                if handler is None:
                    raise ServerError(
                        (
                            "'None' was returned while requesting a "
                            "handler from the router"
                        )
                    )
                else:
                    if not getattr(handler, "__blueprintname__", False):
                        request.endpoint = self._build_endpoint_name(
                            handler.__name__
                        )
                    else:
                        request.endpoint = self._build_endpoint_name(
                            getattr(handler, "__blueprintname__", ""),
                            handler.__name__,
                        )

                # Run response handler
                response = handler(request, *args, **kwargs)
                if isawaitable(response):
                    response = await response
        except CancelledError:
            # If response handler times out, the server handles the error
            # and cancels the handle_request job.
            # In this case, the transport is already closed and we cannot
            # issue a response.
            response = None
            cancelled = True
        except Exception as e:
            # -------------------------------------------- #
            # Response Generation Failed
            # -------------------------------------------- #

            try:
                response = self.error_handler.response(request, e)
                if isawaitable(response):
                    response = await response
            except Exception as e:
                if isinstance(e, SanicException):
                    response = self.error_handler.default(
                        request=request, exception=e
                    )
                elif self.debug:
                    response = HTTPResponse(
                        "Error while handling error: {}\nStack: {}".format(
                            e, format_exc()
                        ),
                        status=500,
                    )
                else:
                    response = HTTPResponse(
                        "An error occurred while handling an error", status=500
                    )
        finally:
            # -------------------------------------------- #
            # Response Middleware
            # -------------------------------------------- #
            # Don't run response middleware if response is None
            if response is not None:
                try:
                    response = await self._run_response_middleware(
                        request, response, request_name=name
                    )
                except CancelledError:
                    # Response middleware can timeout too, as above.
                    response = None
                    cancelled = True
                except BaseException:
                    error_logger.exception(
                        "Exception occurred in one of response "
                        "middleware handlers"
                    )
            if cancelled:
                raise CancelledError()

        # pass the response to the correct callback
        if write_callback is None or isinstance(
            response, StreamingHTTPResponse
        ):
            if stream_callback:
                await stream_callback(response)
            else:
                # Should only end here IF it is an ASGI websocket.
                # TODO:
                # - Add exception handling
                pass
        else:
            write_callback(response)
    ...

    def run(...):
        ...
        server_settings = self._helper(
            host=host,
            port=port,
            debug=debug,
            ssl=ssl,
            sock=sock,
            workers=workers,
            protocol=protocol,
            backlog=backlog,
            register_sys_signals=register_sys_signals,
            auto_reload=auto_reload,
        )
        ...
        try:
            self.is_running = True
            if workers == 1:
                ...
                else:
                    serve(**server_settings)

    ...
    def _helper(...):
        server_settings = {
            ...
            "request_handler": self.handle_request,
            "error_handler": self.error_handler,
            "request_timeout": self.config.REQUEST_TIMEOUT,
            "response_timeout": self.config.RESPONSE_TIMEOUT,
            "keep_alive_timeout": self.config.KEEP_ALIVE_TIMEOUT,
            "request_max_size": self.config.REQUEST_MAX_SIZE,
            ...
        }
        ...
        return server_settings
```

#### middleware

`@app.middleware` decorator로 정의해논 function이 call되어서 request와 response가 middleware를 거쳐서 수정이 될 수 있다.

```python
app = Sanic(__name__)


@app.middleware('request')
async def add_key(request):
    # Arbitrary data may be stored in request context:
    request.ctx.foo = 'bar'


@app.middleware('response')
async def custom_banner(request, response):
    response.headers["Server"] = "Fake-Server"

```

#### router

Sanic 문서의 example code 경우로 설명을 하면 이제 `@app.route('/')` decorator가 있다. 이 decorator로 이제 실행해야할 function(예제에서는 test이름의 function)를 Router class의 attr에 저장해 놓는다.  
```python
from sanic import Sanic
from sanic.response import json

app = Sanic()

@app.route('/')
async def test(request):
    return json({'hello': 'world'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
```

이해를 돕기 위해서 간단하게 example을 만들어보면, `route_example.py`에서 `@app.route()` decorator를 사용하여서 `routes` attr에 function들(handler)를 endpoint uri별로 저장해놓을 수 있다. 

`route_example.py`
```python
class App:
    def __init__(self):
        self.routes = {}

    def route(self, uri):
        def response(handler):
            self.routes.update({uri: handler})
            return handler
        return response


class Request:
    def __init__(self, url, method):
        self.url = url
        self.method = method


app = App()


@app.route('/hello')
def hello(request):
    return 'hello'


@app.route('/world')
def world(request):
    return 'world'


print(hello(Request('/hello', 'GET')))
print(world(Request('/world', 'GET')))
print(app.routes)
print(app.routes.get('/hello'))

```

request side에서 middleware function들이 실행되고 routes에 저장되었던 handler function이 실행이 되고, 이 handler는 `HTTPResponse` class instance를 만들어서 return하게 된다. 그리고 마지막으로 response side에서 request, response input으로 middleware가 실행되고 최종 response를 `transport.write`한다.

```python
from sanic.response import json

app = Sanic()

@app.route('/')
async def test(request):
    return json({'hello': 'world'})
```

`sanic/sanic/response.py`
```python

def json(
    body,
    status=200,
    headers=None,
    content_type="application/json",
    dumps=json_dumps,
    **kwargs
):
    """
    Returns response object with body in json format.
    :param body: Response data to be serialized.
    :param status: Response code.
    :param headers: Custom Headers.
    :param kwargs: Remaining arguments that are passed to the json encoder.
    """
    return HTTPResponse(
        dumps(body, **kwargs),
        headers=headers,
        status=status,
        content_type=content_type,
    )
```
