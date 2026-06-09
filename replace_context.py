import os
import glob

files = glob.glob(r'c:\Gotchaa\lib\features\mini_apps\vibetalk\screens\*.dart')

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace('context.primary', 'Theme.of(context).colorScheme.primary')
    content = content.replace('context.onPrimary', 'Theme.of(context).colorScheme.onPrimary')
    content = content.replace('context.error', 'Theme.of(context).colorScheme.error')
    content = content.replace('context.textTheme', 'Theme.of(context).textTheme')

    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)

print(f"Updated {len(files)} files.")
