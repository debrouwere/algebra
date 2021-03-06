module.exports =
    utils: require './utils'
    parser: require './parser'
    solver: require './solver'
    writer: require './writer'
    generator: require './generator'
    helper: require './helper'

# shortcuts
# shortcuts

module.exports.parse = module.exports.parser.parse
module.exports.test = module.exports.parser.test
module.exports.match = module.exports.parser.match
module.exports.toString = module.exports.writer.toString
module.exports.toLaTeX = module.exports.writer.toLaTeX
module.exports.conjure = module.exports.generator.conjure
module.exports.confuse = module.exports.generator.confuse
module.exports.findMisconceptions = module.exports.helper.findMisconceptions