View = require './LobbyGameRowView.jsx'

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

  render: View.render
})

module.exports = LobbyGameRow

