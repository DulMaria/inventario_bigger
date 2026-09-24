import sys

path = r'lib\modules\administrador\view\admin_page.dart'
try:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # The issue is AppColors.surface and AppColors.backgroundDark, which I did not revert!
    # They got left as AppColors.surface, but I removed the import!
    content = content.replace("AppColors.surface", "Colors.white")
    content = content.replace("AppColors.backgroundDark", "const Color(0xFF1B2A47)")
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Fixed admin page')
except Exception as e:
    print(e)
