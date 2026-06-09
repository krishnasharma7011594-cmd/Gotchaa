import json
import re
import os

def update_en_map():
    json_path = r'c:\Gotchaa\assets\l10n\en.json'
    dart_path = r'c:\Gotchaa\lib\core\l10n\app_localizations_x.dart'
    
    with open(json_path, 'r', encoding='utf-8-sig') as f:
        en_json = json.load(f)
        
    with open(dart_path, 'r', encoding='utf-8') as f:
        dart_content = f.read()
        
    # Build the new 'en' map content
    en_map_lines = []
    for key, value in en_json.items():
        safe_value = value.replace('$', '\\$').replace("'", "''")
        en_map_lines.append(f"      '{key}': r'''{safe_value}''',")
    
    new_en_map_content = "\n".join(en_map_lines)
    
    # Replace the 'en' block
    # Regex to find 'en': { ... }
    # We use a non-greedy match for the content between braces
    pattern = re.compile(r"('en':\s*\{)(.*?)(\},)", re.DOTALL)
    
    def replace_func(match):
        return match.group(1) + "\n" + new_en_map_content + "\n    " + match.group(3)
        
    new_dart_content = pattern.sub(replace_func, dart_content)
    
    with open(dart_path, 'w', encoding='utf-8') as f:
        f.write(new_dart_content)
    
    print("Updated English map in app_localizations_x.dart")

if __name__ == "__main__":
    update_en_map()
