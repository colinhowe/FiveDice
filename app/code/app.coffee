PerudoManager = require './perudo/PerudoManager'

document.addEventListener('DOMContentLoaded', ->
    game = new PerudoManager({"el": document.getElementById("game")})

    # Debugging and tinkering interface
    window.game = game
)
