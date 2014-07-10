React = require 'react'

LobbyGameRow = React.createClass({
  ###
  A game row in the Lobby. Expected props:
    - onGameSelected(key) - callback that will pass the key of the game
      that has been selected.
  ###
  componentWillMount: ->
    @props.secret = localStorage["game:#{@props.key}:secret"]

  handleClick: (e) ->
    @props.onGameSelected(@props.key)

  render: ->
    joinType = "Spectate"
    if @props.secret
        joinType = "Play"
    gameState = @props.game.status
    gameStateMsg = {
        1: "Waiting for players",
        2: "In progress"
    }[gameState]
    return <div><button onClick={ @handleClick }>
        {joinType} Game { @props.game.key } {gameStateMsg}
    </button></div>
})

module.exports = LobbyGameRow

