class App:
    def __init__(self):
        self.routes = {}

    def route(self, uri):
        def response(handler):
            self.routes.update({uri: handler})
            return handler
        return response


class Request:
    def __init__(self, uri, method):
        self.uri = uri
        self.method = method


app = App()


@app.route('/hello')
def hello(request):
    return 'hello'


@app.route('/world')
def world(request):
    return 'world'


hello_request = Request('/hello', 'GET')
world_request = Request('/world', 'GET')
print(hello(hello_request))
print(world(world_request))
print(app.routes)
handler = app.routes.get(hello_request.uri)
print(handler)
print(handler(hello_request))
