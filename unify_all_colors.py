import sys
import re

def unify_colors(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content

        if "package:inventario_bigger/core/config/app_colors.dart" not in content:
            if "import 'package:flutter/material.dart';" in content:
                content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:inventario_bigger/core/config/app_colors.dart';")
            else:
                content = "import 'package:inventario_bigger/core/config/app_colors.dart';\n" + content

        # Replace hardcoded blues with primary/secondary/background
        # Backgrounds: 0xFFF4F6F9, 0xFFE1F3FC, 0xFFF2F2F2, 0xFFF4FAFE
        content = re.sub(r'const Color\(0xFFF4F6F9\)', 'AppColors.backgroundLight', content)
        content = re.sub(r'const Color\(0xFFE1F3FC\)', 'AppColors.backgroundLight', content)
        content = re.sub(r'const Color\(0xFFF4FAFE\)', 'AppColors.backgroundLight', content)
        content = re.sub(r'const Color\(0xFFF2F2F2\)', 'AppColors.backgroundLight', content)
        content = re.sub(r'Colors\.grey\.shade50', 'AppColors.backgroundLight', content)
        
        # Primary: 0xFF1B2A47, 0xFF2FA9E0, 0xFF1E2A32, 0xFF2CB0D9
        content = re.sub(r'const Color\(0xFF1B2A47\)', 'AppColors.primary', content)
        content = re.sub(r'const Color\(0xFF2FA9E0\)', 'AppColors.primary', content)
        content = re.sub(r'const Color\(0xFF1E2A32\)', 'AppColors.textPrimary', content)
        
        # Text Secondary: 0xFF7C8A93, 0xFF64748B
        content = re.sub(r'const Color\(0xFF7C8A93\)', 'AppColors.textSecondary', content)
        content = re.sub(r'const Color\(0xFF64748B\)', 'AppColors.textSecondary', content)

        # White backgrounds for cards
        content = re.sub(r'Colors\.white', 'AppColors.surface', content)
        
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f'Unified {filepath}')
    except Exception as e:
        print(f'Error processing {filepath}: {e}')

import glob

views = glob.glob('lib/modules/**/*.dart', recursive=True)
for view in views:
    unify_colors(view)

