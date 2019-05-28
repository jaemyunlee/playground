import requests

r = requests.get(url='http://127.0.0.1:3000/one/')
print(r.json())
