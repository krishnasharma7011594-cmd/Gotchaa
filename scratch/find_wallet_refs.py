import os
import re

search_terms = [
    r'WalletScreen', r'AddFundsScreen', r'CoinFlowScreen', r'CoinFlowAnalyticsScreen', 
    r'CoinFlowAddExpenseScreen', r'CoinFlowShell', r'UpiScreen', 
    r'addFunds', r'topUp', r'withdraw', r'cashOut', r'tipUser', r'walletBalance', r'gotchaaCash',
    r'karma_transactions', r'wallet_repository', r'upi'
]

compiled_regexes = [re.compile(term, re.IGNORECASE) for term in search_terms]

root_dir = r"C:\Gotchaa"
exclude_dirs = {'.git', '.dart_tool', 'build', 'node_modules', 'scratch', '.gemini'}

results = {}

for dirpath, dirnames, filenames in os.walk(root_dir):
    # Exclude directories
    dirnames[:] = [d for d in dirnames if d not in exclude_dirs]
    
    for filename in filenames:
        if filename.endswith(('.dart', '.yaml', '.js', '.md', '.json')):
            filepath = os.path.join(dirpath, filename)
            try:
                with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                
                matched_terms = []
                for term, rx in zip(search_terms, compiled_regexes):
                    if rx.search(content):
                        matched_terms.append(term)
                
                if matched_terms:
                    results[filepath] = matched_terms
            except Exception as e:
                pass

print(f"Found matches in {len(results)} files:")
for path, terms in sorted(results.items()):
    rel_path = os.path.relpath(path, root_dir)
    print(f"- {rel_path}: {', '.join(terms)}")
