{toString} = require './src/writer'
{conjure, confuse, CONSTANT} = require './src/generator'
expr = conjure CONSTANT

for n in [0, 3, 6, 9, 12, 15]
    toString confuse expr, n


# '(a + b)^c': 'a^c + b^c'
{parse} = require './src/parser'
a = parse '(a+b)^3'
b = parse 'a^3 + b^3'

'a^b * a^c': 'a^(b*c)'