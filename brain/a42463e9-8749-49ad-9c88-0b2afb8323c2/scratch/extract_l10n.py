import re
import json
import os

def extract_l10n():
    path = r'c:\Gotchaa\lib\core\l10n\app_localizations_x.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the data map
    match = re.search(r'static const Map<String, Map<String, String>> data = \{(.*?)\};', content, re.DOTALL)
    if not match:
        print("Could not find data map")
        return

    data_str = match.group(1)
    
    # Split by language blocks
    # regex to find 'lang': { ... }
    lang_blocks = re.findall(r"'(\w+)': \{(.*?)\},", data_str, re.DOTALL)
    
    l10n_data = {}
    for lang, block in lang_blocks:
        keys = re.findall(r"'(\w+)': r'''(.*?)''',", block, re.DOTALL)
        l10n_data[lang] = {k: v for k, v in keys}
        
    return l10n_data

def save_json(l10n_data):
    os.makedirs('l10n_export', exist_ok=True)
    for lang, data in l10n_data.items():
        with open(f'l10n_export/{lang}.json', 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    data = extract_l10n()
    if data:
        save_json(data)
        print("Extracted languages:", list(data.keys()))
