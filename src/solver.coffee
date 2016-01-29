_ = require 'underscore'
{OPERATORS, destructured, substitute} = require './parser'
{isNumber, isExpression} = require './parser'
{modifies} = require './utils'

#
# solving expressions
#

# barring the ability to pattern match on `\sum n choose k x^{n-k} y^{k}`, 
# let's just put in the second-order binomials for now
binomials =
    '(a + b)(a - b)': 'a^2 - b^2'
    '(x + y)^2': 'x^2 + 2 * a * b + b^2'
    '(a - b)^2': 'a^2 - 2 * a * b + b^2'

strategies = binomials

###
NOTE: we can already simplify expressions that match a pattern
but also include some cruft at either end, but we can't yet convert
a^2 + 2*a*b + c + b^2 to (a+b)^2 + c -- unfortunately canonicalization
is not sufficient to catch this, so in addition to canonicalization we'll
have to match all possible permutations of complex expressions
(but only permutations of expressions that consist of expressions, 
every individual expression can be kept in canonical form)
###
factor = modifies isExpression, (expr) ->
    expr = _.map expr, simplify

    for [replacement, pattern] in strategies
        state = {}
        if match expr, pattern, state
            expr = substitute replacement, state

    expr


# calculate a concrete expression (without any symbolic manipulation)
###
NOTE: while `calculate` can do partial calculations that keep
symbols intact, it's not quite smart enough to use the 
associative property to rejig the expression tree, so it 
currently cannot simplify e.g. `3 + a + 5` to `8 + a`
###
calculate = modifies isExpression, destructured (expr, op, l, r) ->
    l = calculate l
    r = calculate r
    if (isNumber l) and (isNumber r)
        OPERATORS[op] l, r
    else
        [op, l, r]


simplify = _.compose calculate, simplify, calculate


module.exports = {
    # (partial) solving
    expand,
    factor,
    calculate,    
    simplify,
}