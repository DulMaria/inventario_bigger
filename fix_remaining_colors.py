import glob
import os

replacements = {
    # Old navy blue -> turquoise primary
    'const Color(0xFF1B2A47)': 'AppColors.primary',
    'Color(0xFF1B2A47)': 'AppColors.primary',
    # Old celeste -> turquoise primary  
    'const Color(0xFF6FC6EE)': 'AppColors.primary',
    'Color(0xFF6FC6EE)': 'AppColors.primary',
    # Old light background -> turquoise background
    'const Color(0xFFF4FAFE)': 'AppColors.backgroundLight',
    'Color(0xFFF4FAFE)': 'AppColors.backgroundLight',
    # Old medium blue
    'const Color(0xFF2FA9E0)': 'AppColors.primary',
    'Color(0xFF2FA9E0)': 'AppColors.primary',
    # Other old blues
    'const Color(0xFF4FC3F7)': 'AppColors.secondary',
    'Color(0xFF4FC3F7)': 'AppColors.secondary',
    'const Color(0xFF0288D1)': 'AppColors.primaryDark',
    'Color(0xFF0288D1)': 'AppColors.primaryDark',
    # Old backgrounds
    'const Color(0xFFF4F6F9)': 'AppColors.backgroundLight',
    'Color(0xFFF4F6F9)': 'AppColors.backgroundLight',
    'const Color(0xFFE1F3FC)': 'AppColors.backgroundLight',
    'Color(0xFFE1F3FC)': 'AppColors.backgroundLight',
}

files = glob.glob('lib/**/*.dart', recursive=True)

for filepath in files:
    # Skip app_colors.dart itself and app.theme.dart
    basename = os.path.basename(filepath)
    if basename in ('app_colors.dart', 'app.theme.dart'):
        continue
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content
        
        for old, new in replacements.items():
            content = content.replace(old, new)
        
        # Ensure import exists if we made changes
        if content != original:
            if "package:inventario_bigger/core/config/app_colors.dart" not in content and "../config/app_colors.dart" not in content and "app_colors.dart" not in content:
                if "import 'package:flutter/material.dart';" in content:
                    content = content.replace(
                        "import 'package:flutter/material.dart';",
                        "import 'package:flutter/material.dart';\nimport 'package:inventario_bigger/core/config/app_colors.dart';"
                    )
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f'Updated: {filepath}')
    except Exception as e:
        print(f'Error: {filepath}: {e}')

print('Done!')
