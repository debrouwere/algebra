_ = require 'underscore'
{isCommutative, isExpression, isNumber, isScalar} = require './parser'
{parse, match, commute} = require './parser'
{VARIABLES, SIGILS} = require './parser'






#
# conjure up long polynomial that still have easy simplifications
# by starting from the solution and then "confusing" it
#

CONSTANT =
    unknowns: 1
    order: [0, 0]
    terms: 1
    magnitude: 3

FIRST_ORDER =
    unknowns: 1
    order: [0, 1]
    terms: 3
    magnitude: 1

SECOND_ORDER =
    unknowns: 1
    order: [0, 2]
    terms: 3
    magnitude: 1

conjure = (options={}) ->
    options = _.defaults options, SECOND_ORDER

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


# TODO: reorder an expression tree into something equivalent
# using commutativity across different depths of the tree
# (e.g. a + b + c => c + b + a)
# -- perhaps this can be accomplished by randomly swapping
# or not swapping at various depths, maybe true "in-depth"
# swapping is not necessary
# -- in fact perhaps if the confusion mechanism is good 
# enough shuffling is not even necessary
shuffle = (expr) ->


strategies = 
    '0': '0 * v'
    '(a+b)^2': 'a^2 + 2*a*b + b^2'

strategies = 
    ([(parse pattern), (parse expansion)] for pattern, expansion of strategies)


# note: the problem with using scalars rather than numbers
# is that the number of unknowns could get unwieldy; while
# the actual complexity of the exercise wouldn't be much higher, 
# not having the ability to just calculate part of it to simplify
# it could be hard on students
confusors =
    'square': (expr) ->
        ['^', ['^', expr, 2], 0.5]
    'cancel': (expr) ->
        a = _.random 100
        ['-', ['+', expr, a], a]
    'null': (expr) ->
        a = _.random 100
        ['+', expr, ['*', a, 0]]
    'multiply': (expr) ->
        a = _.random 100
        ['/', ['*', expr, a], a]
    'power': (expr) ->
        ['^', expr, 1]


choose = (l) ->
    ix = _.random 0, l.length - 1
    l[ix]


###

The confusor mechanism is getting better, but there is still much work to do

- prefer depth, in particular the confusor sometimes retains (expr + a - a) as is, 
  which is what you'd expect when you randomize everything and have a fixed amount
  of iterations, but really, it leads to exercises that don't alwayslook great
- alternatively or additionally, partially solve some of the sums to hide the 
  symmetry that's at the root of every confusor
- figure out how to add in expansions (2 variable polynomials), perhaps by
  updating the conjuring mechanism, or perhaps by allowing c=a+b type replacements
- incorporate negative numbers (which is where it usually gets hairy for students,
  who must keep track of the order of operations)
- it has to be possible to really craft a particular kind of exercises that trains
  one particular rule -- this will be a combination of specifying a subset of 
  confusors, a subset of strategies, and then most importantly making sure
  the conjuring and confusion mechanisms work together so that these strategies
  (e.g. factorization) can actually be employed -- as well as a more advanced
  pattern matcher, which reorders patterns into every possible permutation or 
  into a canonical form, so it can detect e.g. the binomial pattern in
  `a^2 + b^2 + c + d + 2ab`

Also see the notes about conjuring in the design directory. As mentioned there, there's
no harm in manually creating exercises for now and give the other parts of the 
application some love, like the mistake differ/detector/explainer part.

###

confuse = (expr, n) ->
    ###
    e.g. 

        expr = conjure CONSTANT
        for n in [0, 3, 6, 9, 12, 15]
            toString confuse expr, n
    
    ###

    if n is 0
        expr
    else if n is 1
        confusor = _.sample (_.values confusors)
        confusor expr
    else if isScalar expr
        confusor = _.sample (_.values confusors)
        confuse (confusor expr), n - 1
    else
        # confusors can work on the expression as a whole, or on a part of it, 
        # and we want to split this evenly
        [op, l, r] = expr
        nx = _.random n
        nl = _.random n - nx
        nr = n - nx - nl
        (confuse [op, (confuse l, nl), (confuse r, nr)], nx)


module.exports = {
    CONSTANT,
    FIRST_ORDER,
    SECOND_ORDER,
    conjure,
    confuse,
}
