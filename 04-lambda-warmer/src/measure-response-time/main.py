import argparse
import multiprocessing
import os
import time

import aiohttp
import asyncio


def worker(concurrency_target):
    async def fetch(session, url):
        async with session.post(url) as response:
            res = await response.text()
            endtime = time.time()
            print(f"approx elapsed time : {endtime-starttime}")
            return res

    async def run(session, num):
        url = os.environ['URL']
        tasks = []
        for _ in range(num):
            task = asyncio.ensure_future(fetch(session, url))
            tasks.append(task)
        responses = asyncio.gather(*tasks)
        global starttime
        starttime = time.time()
        await responses

    async def main():
        conn = aiohttp.TCPConnector(force_close=True)
        async with aiohttp.ClientSession(connector=conn) as session:
            await run(session, concurrency_target)

    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="set currency number")
    parser.add_argument('concurrency', metavar='N', type=int, help='an integer for setting cucurrency')
    args = parser.parse_args()
    concurrency_target = args.concurrency
    threads = 6
    worker_load = []
    remainder = concurrency_target % threads
    load = int(concurrency_target / threads)

    if remainder:
        worker_load = [load] * (threads - 1)
        worker_load.append(load + remainder)
    else:
        worker_load = [load] * threads

    for load in worker_load:
        p = multiprocessing.Process(target=worker, args=(load,))
        p.start()