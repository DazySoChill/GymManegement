#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fix UTF-8 encoding in memberships.js"""

import codecs

file_path = "wwwroot/js/memberships.js"

# Read file with UTF-8 encoding
with codecs.open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Define replacements
replacements = [
    ('3 thÃ¡ng - Bao gá»"m 2 buá»•i PT/thÃ¡ng', '3 tháng - Bao gồm 2 buổi PT/tháng'),
]

# Apply replacements
for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        print(f"Fixed: {old[:20]}...")
    else:
        print(f"Not found: {old[:20]}...")

# Write back with UTF-8 BOM
with codecs.open(file_path, 'w', encoding='utf-8-sig') as f:
    f.write(content)

print("Done!")
