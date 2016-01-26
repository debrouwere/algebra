# NOTE: in the longer term, I'll be turning the interface into a separate 
# application, with the `algebra` application becoming a library that
# focuses entirely on parsing, analyzing and writing expressions.

$ = require 'jquery'
_ = require 'underscore'
katex = require 'katex'
algebra = require './index'


component = (name, values) ->
    template = $("template##{name}")
    for key, value of values
        $(".#{name}-#{key}").textContent value


render = (el, input) ->
    text = $(el).text()
    input ?= algebra.parse text
    $(el).data 'math', text
    latex = algebra.toLaTeX input
    katex.render latex, el

safeParse = (input) ->
    try
        parse input
    catch
        null


# TODO: it's probably better to replace the layout with a table: 
# solution || right/wrong | complexity | why?
$(document).ready ->
    question = algebra.parse $('table .expression').first().text()
    $('.expression').each (i, el) -> render el

    $('input').keyup ->
        answer = safeParse $('input').val()
        return unless answer

        el = $('tr').last().find('td').get 0
        render el, answer

    $('input').change ->
        box = $('tr').last()
        equation = box.find('td').first()
        explanation = box.find('td').last()

        answer = safeParse $('input').val()
        return unless answer

        if not test question, answer
            box.addClass 'mistake'
            explanation.text '?'

        $('tr.mistake').slice(0, -1).hide()
        $('#answers').append $('tr').last()

    $('a').click (e) ->
        e.preventDefault()
        $('.mistake').show()
