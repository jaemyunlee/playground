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
