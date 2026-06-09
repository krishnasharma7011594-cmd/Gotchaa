import os
import re

def fix_dangling_arrows(directory):
    # Pattern 1: .catchError((e) => \s* }
    pattern1 = re.compile(r'\.catchError\(\(e\)\s*=>\s*\}', re.MULTILINE)
    # Pattern 2: .catchError((e) => \s*\n\s*\}
    pattern2 = re.compile(r'\.catchError\(\(e\)\s*=>\s*\n\s*\}', re.MULTILINE)
    # Pattern 3: .handleError((e) => \s*\n\s*\}
    pattern3 = re.compile(r'\.handleError\(\(e\)\s*=>\s*\n\s*\}', re.MULTILINE)
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = pattern1.sub('.catchError((_) => null)}', content)
                new_content = pattern2.sub('.catchError((_) => null)\n}', new_content)
                new_content = pattern3.sub('.handleError((_) => null)\n}', new_content)
                
                # Special case for the one I saw in language_provider.dart
                new_content = new_content.replace('.catchError((e) => \n    }', '.catchError((_) => null)\n    }')
                new_content = new_content.replace('.catchError((e) => \n    })', '.catchError((_) => null)\n    })')
                
                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Fixed {path}")

if __name__ == "__main__":
    fix_dangling_arrows('lib')
