component = (name, values) ->
    template = $("template##{name}")
    for key, value of values
        $(".#{name}-#{key}").textContent value


render = (el, input) ->
    text = $(el).text()
    input ?= parse text
    $(el).data 'math', text
    latex = toLaTeX input
    katex.render latex, el

safeParse = (input) ->
    try
        parse input
    catch
        null


# TODO: it's probably better to replace the layout with a table: 
# solution || right/wrong | complexity | why?
$(document).ready ->
    question = parse $('#question').text()
    $('.math').each (i, el) -> render el

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