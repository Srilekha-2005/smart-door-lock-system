import requests

url = "http://127.0.0.1:5000/analyze"
payload = {
    "attempts": 6,
    "time_gap": 1
}

response = requests.post(url, json=payload)

print("Status Code:", response.status_code)
print("Response JSON:", response.json())
