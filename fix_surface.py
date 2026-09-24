import sys
import glob

views = glob.glob('lib/modules/**/*.dart', recursive=True)
views.append('lib/core/widgets/custom_drawer.dart')

for filepath in views:
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        content = content.replace("AppColors.surface70", "Colors.white70")
        content = content.replace("AppColors.surface60", "Colors.white60")
        content = content.replace("AppColors.surface24", "Colors.white24")
        content = content.replace("AppColors.background", "AppColors.backgroundLight")
        content = content.replace("AppColors.backgroundLightLight", "AppColors.backgroundLight")
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
    except Exception as e:
        print(f'Error processing {filepath}: {e}')

print('Fixed surface70 and background')
