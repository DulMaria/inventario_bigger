import sys

paths = [
    r'lib\modules\obra\view\gerente_home_view.dart',
    r'lib\core\widgets\custom_drawer.dart',
    r'lib\modules\administrador\view\admin_page.dart'
]

for path in paths:
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()

        content = content.replace("const Color(0xFFF4F6F9)Dark", "const Color(0xFF1B2A47)")
        content = content.replace("const Color(0xFFF4F6F9)Light", "const Color(0xFFF4F6F9)")
        content = content.replace("Colors.whiteLight", "Colors.white")
            
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Fixed {path}')
    except Exception as e:
        print(e)
