import codecs

with codecs.open('lib/modules/obra/view/obra_view.dart', 'r', 'utf-8') as f:
    content = f.read()
print('get.dart' in content)
