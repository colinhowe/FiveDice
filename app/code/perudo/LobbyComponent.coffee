React = require 'react'

LobbyGameRow = require './LobbyGameRow'

LobbyComponent = React.createClass({
    ###
    A game Lobby. Expected props:
        - onGameSelected(key) - callback that will pass the key of the game
          that has been selected.
        - onCreateGame - Callback that should create a game
    ###

    componentWillMount: ->
        @setState({games: @props.games})

    setGames: (games) ->
        @setState({games: games})

    handleGameChange: (gameId) ->
        @props.onGameSelected(gameId)

    render: ->
        gameNodes = @state.games.map((game) =>
            return <LobbyGameRow
                key={game.key}
                game={game}
                onGameSelected={ @handleGameChange }/>
        )
        return <div>
            <input type="text" placeholder="Your name" ref="nick" />
            <input type="number" placeholder="Number of players" ref="numPlayers" />
            <button onClick={@onCreateGame}>Create Game</button>
            <div>{ gameNodes }</div>
        </div>
      
    onCreateGame: ->
        nick = @refs.nick.getDOMNode().value.trim()
        numPlayers = parseInt(@refs.numPlayers.getDOMNode().value.trim())
        @props.onCreateGame(nick=nick, numPlayers=numPlayers)

})

module.exports = LobbyComponent
