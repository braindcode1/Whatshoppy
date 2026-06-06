import urllib.request
import urllib.error
import json

req = urllib.request.Request(
    'http://127.0.0.1:8000/predict-price',
    data=json.dumps({
        'Brand': 'Nike',
        'Category': 'T-Shirt',
        'Color': 'Black',
        'Size': 'L',
        'Material': 'Cotton',
        'Gender': 'Men',
        'Season': 'Summer',
        'Brand_Tier': 'Premium'
    }).encode('utf-8'),
    headers={'Content-Type': 'application/json'},
    method='POST'
)

try:
    response = urllib.request.urlopen(req)
    print(response.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print(e.read().decode('utf-8'))
