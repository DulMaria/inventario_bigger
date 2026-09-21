import codecs

file_path = 'lib/modules/auth/service/auth_service.dart'

with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

import re

# We just want to replace maybeSingle() with limit(1).maybeSingle() after eq('estado', true)
content = re.sub(
    r"\.eq\('estado',\s*true\)\s*\.maybeSingle\(\)",
    r".eq('estado', true).limit(1).maybeSingle()",
    content
)

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)

file_path2 = 'lib/core/widgets/custom_drawer.dart'
with codecs.open(file_path2, 'r', 'utf-8') as f2:
    content2 = f2.read()
    
content2 = re.sub(
    r"\.eq\('estado',\s*true\)\s*\.maybeSingle\(\)",
    r".eq('estado', true).limit(1).maybeSingle()",
    content2
)

with codecs.open(file_path2, 'w', 'utf-8') as f2:
    f2.write(content2)

