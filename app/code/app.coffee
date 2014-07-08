require 'pusher'
PerudoWidget = require './perudo/Perudo'

document.addEventListener('DOMContentLoaded', ->
    console.log Pusher
    game = PerudoWidget.create({"el": document.getElementById("game")})

    # Debugging and tinkering interface
    window.game = game
)
