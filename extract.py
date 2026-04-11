import sys, re
data = sys.stdin.read()
match = re.search(r'"deployedTo"\s*:\s*"([^"]+)"', data)
if match:
    print(match.group(1))
else:
    match = re.search(r'Deployed to:\s*(0x[a-fA-F0-9]+)', data)
    if match:
        print(match.group(1))
