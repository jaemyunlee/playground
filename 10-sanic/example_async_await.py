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
