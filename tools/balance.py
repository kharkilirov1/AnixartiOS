import re, sys
path = sys.argv[1]
s = open(path, encoding='utf-8').read()
s = re.sub(r'"(?:[^"\\]|\\.)*"', '""', s)
s = re.sub(r"'(?:[^'\\]|\\.)*'", "''", s)
s = re.sub(r'//.*', '', s)
s = re.sub(r'/\*.*?\*/', '', s, flags=re.S)
print(path, '| braces:', s.count('{') - s.count('}'), '| parens:', s.count('(') - s.count(')'), '| brackets:', s.count('[') - s.count(']'))
