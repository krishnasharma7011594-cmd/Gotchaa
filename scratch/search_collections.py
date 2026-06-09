import os
import re

target_dir = r"C:\Gotchaa\lib"
patterns = [
    "stories", "grievances", "takedown_requests", 
    "deletionLog", "usernames", "presence", 
    "trending", "karma_transactions", "followers", "following"
]

regex = re.compile("|".join(patterns), re.IGNORECASE)

print("Starting scan of " + target_dir)
for root, dirs, files in os.walk(target_dir):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    for i, line in enumerate(f, 1):
                        if regex.search(line):
                            # Print only matching lines with context
                            print(f"{path}:{i} -> {line.strip()}")
            except Exception as e:
                pass
