_ = require 'underscore'
{isCommutative, isNumber, isScalar} = require './parser'
{parse, match, commute} = require './parser'
{VARIABLES, SIGILS} = require './parser'


strategies = 
    '0': '0 * v'
    '(a+b)^2': 'a^2 + 2*a*b + b^2'

strategies = 
    ([(parse pattern), (parse expansion)] for pattern, expansion of strategies)


mistakes =
    'misapplication of distributivity':
        '(a + b)^c': 'a^c + b^c'
    'misapplication of power to a power':
        'a^b^c': 'a^(b^c)'
        'a^b^c': 'a^(b+c)'
    'misapplication of multiplying different powers of the same base':
        'a^b * a^c': 'a^(b*c)'
    # and so on...

# console.log diff (parse '3 + (55 + 7) * 12^5'), parse ('4 + (7 + 55) * 12^(4+2)')


# TODO: randomize, add opportunities
# NOTE: this is the opposite of solving, though for solving
# we can probably just use the `executable` function and 
# then fold everything up, so solving and confusing are
# not necessarily similar code paths
# NOTE: by using `this` for random number generation, 
# we can further control the difficulty (e.g. 
# only generate small numbers)
# NOTE: these opportunities rely on the fact that confusion
# happens recursively, so that while e.g. expr + 1700 * 0
# is a no-brainer, expr + 1700 * 9^2 * (8 - 2^3) does
# take a couple of steps to properly simplify
# (but again, the really interesting stuff will happen when
# we have a good swapping mechanism so not everything is 
# adjacent until the student makes it so)
confusors =
    'swap':
        condition: isCommutative
        weight: 1
        op: commute
    'sum':
        condition: isNumber
        weight: 1
        op: (a) ->
            b = this.integer()
            ['+', b, a - b]
    'cancel':
        condition: no
        weight: 1
        op: (expr) ->
            a = this.scalar()
            ['-', ['+', expr, a], a]
    'null':
        condition: isScalar
        weight: 1
        op: (expr) ->
            a = this.scalar()
            ['+', expr, ['*', a, 0]]
    'power':
        condition: no
        weight: 1
        op: (expr) ->
            ['^', expr, 1]


choose = (l) ->
    ix = _.random 0, l.length - 1
    l[ix]


# TODO: make this probabilistic, but with a fixed 
# amount of confusions (only *where* the confusions
# happen should be probabilistic)
# TODO: also swap stuff (similar to the permutations
# we'll need for more powerful solving)
# TODO: a mix of concrete (numbers) and abstract (variables)
class Context
    # TODO: figure out symbols that are actually still available
    constructor: ->
        @freeSymbols = ['x', 'y', 'z']

    # TODO
    symbol: ->
        choose ['x', 'y', 'z']
    
    scalar: ->
        (choose [@symbol, @integer])()
    
    integer: ->
        _.random -10, 10


# TODO: hmm, I think this has all the right elements --
# it has the recursion, it has the "make stuff more difficult"
# strategies as well as the "split into factors" strategies, 
# but I need to figure out how to make all of this work together
# nicely
factor = (expr) ->
    for [pattern, replacement] in strategies
        #console.log expr, pattern
        state = {}
        if match expr, pattern, state
            expr = substitute replacement, state

    expr


exports.confuse = (expr, iterations=1) ->
    return expr unless iterations

    # TODO: in addition to using more strategies, 
    # also use equivalencies (e.g. replace a number
    # with a sum of two other numbers, then
    # maybe confuse those further)
    expr = factor expr

    # confuse
    opportunities = []
    for name, confusor of confusors
        isApplicable = confusor.condition or (-> yes)
        continue unless isApplicable expr
        for i in _.range confusor.weight
            opportunities.push confusor.op

    # TODO: maintain and customize context
    context = new Context()
    confusor = choose opportunities
    expr = confusor.call context, expr

    # recurse
    if isExpression expr
        for el, i in expr
            break unless i and iterations
            replacement = confuse el, iterations
            if el isnt replacement
                expr[i] = replacement
                iterations -= 1

    expr


exports.conjure = (options={}) ->
    options = _.defaults options, 
        unknowns: 1
        order: [0, 2]
        terms: 3
        magnitude: 1

    C = 10 ** options.magnitude
    unknowns = _.shuffle VARIABLES

    # TODO: different ways to concatenate multiple unknowns
    # TODO: term skipping
    terms = []

    [lo, hi] = options.order
    for u in _.range options.unknowns
        x = unknowns.pop()
        for n in _.range lo, hi + 1
            op = _.sample ['+', '-']
            c = _.random 1, C
            
            # simplify the expression where possible
            # (might also be able to do this by passing
            # the expression to `simplify` afterwards)
            if n is 0
                term = c
            else if n is 1
                term = ['*', c, x]
            else
                term = ['*', c, ['^', x, n]]

            if terms.length
                terms = [[op, term, terms[0]]]
            else
                terms.push term

    terms[0]
