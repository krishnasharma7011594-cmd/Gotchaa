import re
import sys

def check_duplicates(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all maps (language blocks)
    # They look like 'en': { ... }, or 'hi': { ... }
    # This regex is a bit simplified but should work for this structure
    map_matches = re.finditer(r"'([a-z]{2})':\s*\{", content)
    
    maps = []
    last_start = -1
    last_lang = ""
    
    for match in map_matches:
        if last_start != -1:
            maps.append((last_lang, content[last_start:match.start()]))
        last_start = match.start()
        last_lang = match.group(1)
    
    # Add the last map
    if last_start != -1:
        maps.append((last_lang, content[last_start:]))

    all_errors = []
    for lang, map_content in maps:
        # Find all keys like 'key':
        keys = re.findall(r"'([a-zA-Z0-9_]+)':", map_content)
        seen = set()
        duplicates = []
        for k in keys:
            if k in seen:
                duplicates.append(k)
            seen.add(k)
        
        if duplicates:
            all_errors.append(f"Language '{lang}' has duplicate keys: {', '.join(set(duplicates))}")

    if all_errors:
        print("\n".join(all_errors))
    else:
        print("No duplicates found.")

if __name__ == "__main__":
    check_duplicates(r"c:\Gotchaa\lib\core\l10n\app_localizations_x.dart")
