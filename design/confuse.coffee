{toString} = require './src/writer'
{conjure, confuse, CONSTANT} = require './src/generator'
expr = conjure CONSTANT

for n in [0, 3, 6, 9, 12, 15]
    toString confuse expr, n