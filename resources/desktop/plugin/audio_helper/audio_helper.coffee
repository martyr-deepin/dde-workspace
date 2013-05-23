class AudioHelper extends Widget
    constructor: (@id) ->
        super
        @img = create_img(null, "#{_plugin.path}/main.png", @element)
    do_click: (e)->
        alert("click me?")

_plugin.inject_css("audio_helper")
_plugin.wrap_element(new AudioHelper(_plugin.id).element)
