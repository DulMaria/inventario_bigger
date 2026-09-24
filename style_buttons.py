import re
import glob

files = glob.glob('lib/modules/**/crear_*.dart', recursive=True) + glob.glob('lib/modules/**/editar_*.dart', recursive=True)

for filepath in files:
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Find child: ElevatedButton(
        # We need to change it to child: ElevatedButton.icon( icon: const Icon(Icons.add, color: Colors.white), label: ... )
        # Let's replace 'child: ElevatedButton(' with 'child: ElevatedButton.icon('
        # And then replace 'child: _cargando' with 'label: _cargando'
        
        new_content = re.sub(r'child:\s*ElevatedButton\(', r'child: ElevatedButton.icon(\n                  icon: const Icon(Icons.add, color: Colors.white),', content)
        new_content = re.sub(r'child:\s*_cargando', r'label: _cargando', new_content)
        new_content = re.sub(r'child:\s*const\s*Text', r'label: const Text', new_content)
        new_content = re.sub(r'child:\s*Text\(', r'label: Text(', new_content)

        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f'Modified buttons in {filepath}')
            
    except Exception as e:
        print(f'Error processing {filepath}: {e}')

