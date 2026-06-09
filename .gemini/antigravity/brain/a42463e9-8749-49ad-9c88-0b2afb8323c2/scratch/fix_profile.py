import os

file_path = r'c:\Gotchaa\lib\features\profile\presentation\screens\user_profile_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_content = content.replace("Text('Error: $e')", "Text(context.tr('error_prefix', args: [e.toString()]))")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Done")
