import urllib.request
import urllib.error
import json
import requests
import glob

BASE_URL = 'http://127.0.0.1:8000'
results = {}

# The 5 Predefined Static Accounts
accounts = [
    ('admin@onion.ai', 'Admin@Onion2026', 'Administrator', 'Super Admin'),
    ('inspector1@onion.ai', 'Inspector1@2026', 'Ramesh Shinde', 'Senior Quality Inspector'),
    ('inspector2@onion.ai', 'Inspector2@2026', 'Sunita Patil', 'Quality Assessor'),
    ('inspector3@onion.ai', 'Inspector3@2026', 'Arun Kumar', 'Procurement Inspector'),
    ('inspector4@onion.ai', 'Inspector4@2026', 'Vikram Deshmukh', 'Audit Assessor'),
]

# TESTS 1 - 5: Login with each of the 5 valid accounts
tokens = []
for idx, (ident, pwd, expected_name, expected_role) in enumerate(accounts, 1):
    payload = json.dumps({'username_or_email': ident, 'password': pwd}).encode('utf-8')
    req = urllib.request.Request(f'{BASE_URL}/auth/login', data=payload, headers={'Content-Type': 'application/json'})
    res = urllib.request.urlopen(req)
    data = json.loads(res.read())
    assert data['status'] == 'SUCCESS'
    assert data['user']['name'] == expected_name
    assert data['user']['role'] == expected_role
    tokens.append(data['token'])
    results[f'TEST {idx}'] = f'PASS: Logged in Account #{idx} ({ident}) as {expected_name} ({expected_role})'

# TEST 6: Unknown account rejected
payload = json.dumps({'username_or_email': 'hacker@onion.ai', 'password': 'Password123'}).encode('utf-8')
req = urllib.request.Request(f'{BASE_URL}/auth/login', data=payload, headers={'Content-Type': 'application/json'})
try:
    urllib.request.urlopen(req)
    results['TEST 6'] = 'FAIL: Unknown account was accepted'
except urllib.error.HTTPError as e:
    err = json.loads(e.read())
    assert e.code == 401
    assert err['detail'] == 'Invalid username or password'
    results['TEST 6'] = f'PASS: Unknown account rejected with 401: "{err["detail"]}"'

# TEST 7: Valid username with incorrect password rejected
payload = json.dumps({'username_or_email': 'admin@onion.ai', 'password': 'WrongPassword123'}).encode('utf-8')
req = urllib.request.Request(f'{BASE_URL}/auth/login', data=payload, headers={'Content-Type': 'application/json'})
try:
    urllib.request.urlopen(req)
    results['TEST 7'] = 'FAIL: Wrong password accepted'
except urllib.error.HTTPError as e:
    err = json.loads(e.read())
    assert e.code == 401
    assert err['detail'] == 'Invalid username or password'
    results['TEST 7'] = f'PASS: Wrong password rejected with 401: "{err["detail"]}"'

# TEST 8: Access protected endpoint /auth/me without authentication
req = urllib.request.Request(f'{BASE_URL}/auth/me')
try:
    urllib.request.urlopen(req)
    results['TEST 8'] = 'FAIL: Protected endpoint allowed without authentication'
except urllib.error.HTTPError as e:
    err = json.loads(e.read())
    assert e.code == 401
    results['TEST 8'] = f'PASS: Protected API rejected without token (code {e.code}): "{err["detail"]}"'

# TEST 9: Authenticated API access
token = tokens[1] # Account 2: Ramesh Shinde
req = urllib.request.Request(f'{BASE_URL}/auth/me', headers={'Authorization': f'Bearer {token}'})
res = urllib.request.urlopen(req)
user_data = json.loads(res.read())
assert user_data['id'] == 'acc-2'
results['TEST 9'] = f'PASS: Authenticated access verified for {user_data["name"]} (ID: {user_data["id"]})'

# TEST 10: Logout and verify token is invalidated
logout_payload = json.dumps({'token': token}).encode('utf-8')
logout_req = urllib.request.Request(f'{BASE_URL}/auth/logout', data=logout_payload, headers={'Content-Type': 'application/json'})
logout_res = urllib.request.urlopen(logout_req)
assert json.loads(logout_res.read())['status'] == 'SUCCESS'
# Verify token now rejected
req = urllib.request.Request(f'{BASE_URL}/auth/me', headers={'Authorization': f'Bearer {token}'})
try:
    urllib.request.urlopen(req)
    results['TEST 10'] = 'FAIL: Token still worked after logout'
except urllib.error.HTTPError as e:
    assert e.code == 401
    results['TEST 10'] = 'PASS: Token invalidated successfully upon logout; protected API rejected'

# TEST 11: Create inspection while logged in (associated with account)
token = tokens[0] # Account 1: Admin
insp_body = json.dumps({
    'id': 'INSP-2026-STATIC-001',
    'variety': 'Red Onion',
    'grade': 'A',
    'status': 'Healthy',
    'detections': []
}).encode('utf-8')
sync_req = urllib.request.Request(
    f'{BASE_URL}/inspections/sync',
    data=insp_body,
    headers={'Content-Type': 'application/json', 'Authorization': f'Bearer {token}'}
)
sync_res = urllib.request.urlopen(sync_req)
sync_data = json.loads(sync_res.read())
assert sync_data['status'] == 'SUCCESS'
assert sync_data['user_id'] == 'acc-1'

# Verify retrieving inspection belongs to acc-1
get_req = urllib.request.Request(f'{BASE_URL}/inspections', headers={'Authorization': f'Bearer {token}'})
get_res = urllib.request.urlopen(get_req)
user_inspections = json.loads(get_res.read())
assert len(user_inspections) >= 1
assert user_inspections[0]['id'] == 'INSP-2026-STATIC-001'
results['TEST 11'] = f'PASS: Inspection associated strictly with user_id {sync_data["user_id"]} and retrieved securely'

# TEST 12: Real AI prediction (/predict)
test_imgs = glob.glob('C:/Users/Tharun Balaji/Downloads/onion-main/onion-ai/dataset/test/*/*.jpg')
with open(test_imgs[0], 'rb') as f:
    resp = requests.post(f'{BASE_URL}/predict', files={'image': ('sample.jpg', f, 'image/jpeg')})
assert resp.status_code == 200
pred_data = resp.json()
assert 'prediction' in pred_data
assert 'confidence' in pred_data
assert 'probabilities' in pred_data
results['TEST 12'] = f'PASS: AI prediction intact ({pred_data["prediction"]}, {pred_data["confidence"]}%)'

# TEST 13: Report & Sync endpoints
status_req = urllib.request.Request(f'{BASE_URL}/sync/status')
status_data = json.loads(urllib.request.urlopen(status_req).read())
assert status_data['status'] == 'ONLINE'
results['TEST 13'] = f'PASS: Reports & Sync status operational ({status_data["status"]})'

print('========================================')
print('        COMPLETE 13-TEST RESULTS        ')
print('========================================')
for k, v in results.items():
    print(f'{k}: {v}')
print('========================================')
