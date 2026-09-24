import re

files = ['lib/modules/compras/view/pisos_cotizar_view.dart', 'lib/modules/compras/view/pisos_comprar_view.dart']

for filepath in files:
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Let's find: Text( '', and wrap it in Flexible or Expanded if it's in a Row.
        # Actually, let's just find the first Text after the icon and wrap it.
        # It's safer to just wrap it via regex.
        
        # In a Row, usually the floor name is something like:
        # Text(
        #   '',
        #   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        # )
        
        # Let's just wrap any Text with '' inside a Flexible
        
        # Regex to find Text(''...
        new_content = re.sub(
            r"(Text\(\s*'\$\{piso\['nombre'\]\}'[\s\S]*?\),)",
            r"Flexible(child: \1)",
            content
        )
        
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f'Fixed overflow in {filepath}')
            
    except Exception as e:
        print(f'Error processing {filepath}: {e}')
