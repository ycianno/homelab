import sys, json, urllib.request, os

# Resolve absolute path to docs directory relative to this script
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DOC_PATH = os.path.join(SCRIPT_DIR, "../docs/Recruitment - Zoho Recruit API Reference.md")
URL = "http://10.0.0.67:5678/webhook/zohoFieldsExtr1/webhook/zoho-api-fields-extractor"

print("Triggering Zoho API field extraction from n8n...")
try:
    req = urllib.request.Request(URL, method="POST")
    with urllib.request.urlopen(req) as r:
        body = r.read().decode("utf-8")
        status = r.status
except Exception as e:
    print(f"Error: Failed to connect to n8n ({e})")
    sys.exit(1)

if status != 200:
    print(f"Error: n8n returned status code {status}")
    print(body)
    sys.exit(1)

try:
    data = json.loads(body)
    if isinstance(data, list):
        data = data[0]
    markdown = data.get("markdown", body)
except Exception:
    markdown = body

# Ensure target directory exists
os.makedirs(os.path.dirname(DOC_PATH), exist_ok=True)

print(f"Updating documentation at: {DOC_PATH}")
with open(DOC_PATH, "w", encoding="utf-8") as f:
    f.write(markdown)

print("Success! API Reference updated.")
