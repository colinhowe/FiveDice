React = require 'react'
PerudoManager = require './perudo/PerudoManager'

document.addEventListener('DOMContentLoaded', ->
    React.renderComponent(<PerudoManager />, document.getElementById("game"))

    # Debugging and tinkering interface
    window.game = game
)
