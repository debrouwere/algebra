exports.needs = (condition, f) ->
    (expr) ->
        if condition expr
            f expr
        else
            throw Error()

exports.modifies = (condition, f) ->
    (expr, options...) ->
        if condition expr
            f expr, options...
        else
            expr

exports.apply = (f) ->
    (args) ->
        f.apply this, args

exports.sum = (l) ->
    l.reduce (a, b) -> a + b
