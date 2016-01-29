_ = require 'underscore'
{OPERATORS, destructured, substitute, calculate} = require './parser'
{isNumber, isExpression} = require './parser'
{modifies} = require './utils'

#
# solving expressions
#

use = (strategies) ->
    applyStrategies = modifies isExpression, (expr) ->
        expr = _.map expr, applyStrategies

        for [pattern, replacement] in strategies
            state = {}
            if match expr, pattern, state
                expr = substitute replacement, state

        expr

# barring the ability to pattern match on `\sum n choose k x^{n-k} y^{k}`, 
# let's just put in the second-order binomials for now
binomials =
    '(a + b)(a - b)': 'a^2 - b^2'
    '(x + y)^2': 'x^2 + 2 * a * b + b^2'
    '(a - b)^2': 'a^2 - 2 * a * b + b^2'

###
NOTE: we can already simplify expressions that match a pattern
but also include some cruft at either end, but we can't yet convert
a^2 + 2*a*b + c + b^2 to (a+b)^2 + c -- unfortunately canonicalization
is not sufficient to catch this, so in addition to canonicalization we'll
have to match all possible permutations of complex expressions
(but only permutations of expressions that consist of expressions, 
every individual expression can be kept in canonical form)
###
expand = use binomials
factor = use _.invert binomials


# not fully satisfactory, of course...
# TODO: simplifications such as `aaa = a^3`, `c + 2c = 3c` and perhaps even
# `5a - 5a^2 = 5(a - a^2)`
simplify = _.compose calculate, factor, calculate


module.exports = {
    # (partial) solving
    expand,
    factor,
    calculate,    
    simplify,
}