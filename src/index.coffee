module.exports =
    utils: require './utils'
    parser: require './parser'
    writer: require './writer'
    generator: require './generator'
    helper: require './helper'

# shortcuts
module.exports.parse = module.exports.parser.parse
module.exports.toString = module.exports.writer.toString
module.exports.toLaTeX = module.exports.writer.toLaTeX
module.exports.conjure = module.exports.generator.conjure
module.exports.confuse = module.exports.generator.confuse
module.exports.findMisconceptions = module.exports.helper.findMisconceptions