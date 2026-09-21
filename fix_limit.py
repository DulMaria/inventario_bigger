import codecs
import re

file_path = 'lib/modules/auth/service/auth_service.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

# Replace all occurrences of maybeSingle() after eq('estado', true) with limit(1).maybeSingle()
content = content.replace(".eq('estado', true)\n          .maybeSingle();", ".eq('estado', true)\n          .limit(1)\n          .maybeSingle();")
content = content.replace(".eq('estado', true)\n            .maybeSingle();", ".eq('estado', true)\n            .limit(1)\n            .maybeSingle();")


with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)
    
file_path2 = 'lib/core/widgets/custom_drawer.dart'
with codecs.open(file_path2, 'r', 'utf-8') as f2:
    content2 = f2.read()
    
content2 = content2.replace(".eq('estado', true)\n                .maybeSingle();", ".eq('estado', true)\n                .limit(1)\n                .maybeSingle();")
with codecs.open(file_path2, 'w', 'utf-8') as f2:
    f2.write(content2)

