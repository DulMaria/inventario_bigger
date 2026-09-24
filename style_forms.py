import sys
import glob

files = glob.glob('lib/modules/**/crear_*.dart', recursive=True) + glob.glob('lib/modules/**/editar_*.dart', recursive=True)

for filepath in files:
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # We look for ElevatedButton( ... child: Text('Guardar...') or child: Text('Crear...') or child: _cargando ? ... : Text('Crear...')
        # Actually the user wants "si hay botones como el de agregar que este con un +"
        
        # We can just do a very targeted replace if we find ElevatedButton and it has no icon.
        if "ElevatedButton(" in content:
            # Let's replace ElevatedButton( with ElevatedButton.icon(
            # But wait, ElevatedButton.icon takes 'label' instead of 'child' and 'icon'.
            # We can't just blind replace. We have to parse it or use Regex.
            pass
            
    except Exception as e:
        print(f'Error processing {filepath}: {e}')

