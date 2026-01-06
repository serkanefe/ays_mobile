import os, requests
os.environ['DATABASE_URL'] = 'postgresql://ays:ayspass@localhost:55432/ays'
resp = requests.post('http://localhost:5000/api/auth/login', json={'email':'manager1@example.com','password':'Test123'})
print('status', resp.status_code)
print(resp.text)
