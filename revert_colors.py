import sys

color_map = {
    'AppColors.backgroundLight': 'const Color(0xFFF4F6F9)',
    'AppColors.backgroundDark': 'const Color(0xFF1B2A47)',
    'AppColors.surface': 'Colors.white',
    'AppColors.primary': 'const Color(0xFF1B2A47)',
    'AppColors.secondary': 'const Color(0xFF2FA9E0)',
    'AppColors.success': 'const Color(0xFF22C55E)',
    'AppColors.error': 'const Color(0xFFEF4444)',
    'AppColors.warning': 'const Color(0xFFF59E0B)',
    'AppColors.info': 'const Color(0xFF3B82F6)',
    'AppColors.textPrimary': 'const Color(0xFF1E293B)',
    'AppColors.textSecondary': 'const Color(0xFF64748B)',
    'AppColors.border': 'const Color(0xFFE2E8F0)',
}

files_to_revert = [
    r'lib\modules\obra\view\gerente_home_view.dart',
    r'lib\modules\obra\view\usuarios_por_obra_view.dart',
    r'lib\modules\obra\view\proformas_gerente_view.dart',
    r'lib\core\widgets\custom_drawer.dart',
    r'lib\core\widgets\animated_pressable.dart',
    r'lib\modules\administrador\view\admin_page.dart'
]

for path in files_to_revert:
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        content = content.replace("import 'package:inventario_bigger/core/config/app_colors.dart';", "")
        content = content.replace("import 'package:inventario_bigger/core/theme/app_colors.dart';", "")

        for app_color, hex_color in color_map.items():
            content = content.replace(app_color, hex_color)
            
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Reverted {path}')
    except Exception as e:
        print(f'Failed {path}: {e}')
