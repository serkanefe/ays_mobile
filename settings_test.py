import os, requests
os.environ['DATABASE_URL']='postgresql://ays:ayspass@localhost:55432/ays'
payload={'site_name':'Test','rent_due_day':1}
r=requests.post('http://127.0.0.1:5000/api/settings', json=payload)
print(r.status_code)
print(r.text)
