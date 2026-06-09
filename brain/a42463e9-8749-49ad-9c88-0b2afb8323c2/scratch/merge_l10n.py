import os
import re
import json

def merge_l10n():
    dart_path = r'c:\Gotchaa\lib\core\l10n\app_localizations_x.dart'
    json_dir = r'c:\Gotchaa\brain\a42463e9-8749-49ad-9c88-0b2afb8323c2\scratch\l10n_export'
    
    with open(dart_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Process each JSON file
    for filename in os.listdir(json_dir):
        if not filename.endswith('.json'):
            continue
        
        lang_code = filename.replace('.json', '').replace('_new', '')
        with open(os.path.join(json_dir, filename), 'r', encoding='utf-8') as f:
            new_translations = json.load(f)
        
        # Find the block for this language
        lang_pattern = rf"    '{lang_code}': \{{(.*?)\s*    }},"
        match = re.search(lang_pattern, content, re.DOTALL)
        
        if match:
            existing_block = match.group(1)
            # Add new keys if they don't exist
            for key, value in new_translations.items():
                if f"'{key}':" not in existing_block:
                    existing_block += f"      '{key}': r'''{value}''',\n"
            
            # Replace the old block with the updated one
            new_block = f"    '{lang_code}': {{{existing_block}    }},"
            content = content.replace(match.group(0), new_block)
        else:
            # If language doesn't exist, create it (shouldn't happen for existing ones but good for new ones)
            new_block = f"    '{lang_code}': {{\n"
            for key, value in sorted(new_translations.items()):
                new_block += f"      '{key}': r'''{value}''',\n"
            new_block += "    },"
            
            # Insert before the last };
            content = content.replace('  };\n}', f"{new_block}\n  }};\n}}")

    with open(dart_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("Successfully merged new keys into app_localizations_x.dart")

if __name__ == "__main__":
    merge_l10n()
