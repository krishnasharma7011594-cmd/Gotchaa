import json

with open('en.json', 'r', encoding='utf-8') as f:
    en = json.load(f)
with open('ar.json', 'r', encoding='utf-8') as f:
    ar = json.load(f)

missing = [k for k in en if k not in ar]
print(f"Arabic missing {len(missing)} keys out of {len(en)}")
print("Sample missing:", missing[:10])
