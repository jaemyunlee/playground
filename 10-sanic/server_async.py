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