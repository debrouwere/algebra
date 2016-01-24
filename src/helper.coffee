{patterns, match} = require './parser'
{toString} = require './writer'


# NOTE: one could even imagine using the confusion mechanism with 
# these mistakes instead of valid confusors/strategies, and then 
# asking the student whether A is or is not equal to B
mistakes =
    'misapplication of distributivity': patterns {
        '(a + b)^c': 'a^c + b^c'
    }
    'misapplication of power to a power': patterns {
        'a^(b^c)': 'a^b^c'
        'a^(b+c)': 'a^b^c'
    }
    'misapplication of multiplying different powers of the same base': patterns {
        'a^(b*c)': 'a^b * a^c'
    }

# NOTE: ideally match would return the state, so we can ask
# "instead of matching a specific pattern, specifically
# match for x and y, because those are the variables
# that were used in the previous expression and this
# expression builds on that"
misconceptions = (prev, curr) ->
    issues = []

    for name, pattern of mistakes
        for [left, right] in pattern
            issue =
                name: name
                prev: toString prev
                curr: toString curr
            
            if (match prev, left) and (match curr, right)
                issues.push issue
            if (match prev, right) and (match curr, left)
                issues.push issue

    issues


module.exports = {
    mistakes,
    misconceptions,
}