$ = require 'jquery'
React = require 'react'

Dice = require './Dice'
GameStore = require './GameStore'

GameActions = require './GameActions'

LastGambleComponent = React.createClass({
  render: ->
    return <div>
        <p>Last gamble was {@props.lastGamble.quantity} {@props.lastGamble.value}s</p>
    </div>
})

PlayerListComponent = React.createClass({
  render: ->
    players = (player for _, player of @props.players)
    playerNodes = players.map((player) ->
      <li key={player.nick}>{player.nick}</li>
    )
    return <ul>{ playerNodes }</ul>
})

GambleComponent = React.createClass({
  render: ->
    <div>
      <input ref="quantity" type="number" placeholder="number of dice" />
      <input ref="value" type="number" placeholder="value of dice" />
      <button onClick={@doGamble}>Gamble</button>
      <button onClick={@doBullshit}>Call Bullshit</button>
    </div>

  doGamble: ->
    value = parseInt(@refs.value.getDOMNode().value.trim())
    quantity = parseInt(@refs.quantity.getDOMNode().value.trim())
    @props.doGamble(value, quantity)

  doBullshit: ->
    @props.doBullshit()
})

GameComponent = React.createClass({
    _onGameChanged: (newGameState) ->
      # Copy local data from the old game as we don't always get given that in
      # updates
      currentRound = @state.game.round
      currentStatus = @state.game.status

      if @state.game.localPlayer
        newGameState.localPlayer = @state.game.localPlayer
      newGameState.updateState()

      if newGameState.secret and not @state.secret
        localStorage["game:#{newGameState.id}:secret"] = newGameState.secret
        @setState({secret: newGameState.secret, game: newGameState})
      else:
        @setState({game: newGameState})

      needDice = (
        @state.game.round != currentRound or
        @state.game.status != currentStatus or
        (@state.secret and !@state.dice and @state.game.inProgress)
      )

      if needDice
        GameStore.fetchById(@state.game.id, @state.secret, @gotNewDice)

    _syncGame: (data) ->
      game = GameStore.updateGameWithNewData(@state.game, data)
      @setState(game: game)

    gotNewDice: (game, dice, localPlayerId) ->
      @setState({dice: dice})

    getInitialState: ->
        return {
          loading: true
        }

    componentDidMount: ->
      gameId = @props.id
      secret = localStorage["game:#{gameId}:secret"]
      @setState({secret: secret})
      window.game = @

      GameStore.fetchById(gameId, secret, @gameLoaded)

    gameLoaded: (game, dice, localPlayerId) ->
      @setState({loading: false, game: game, dice: dice})
      GameStore.watch(@props.pusher, game.id)
      GameStore.subscribe(@_onGameChanged)

    componentWillUnmount: ->
      GameStore.unwatch(@props.pusher, @state.game.id)
      GameStore.unsubscribe(@_onGameChanged)

    render: ->
        if @state.loading
          return <p>Loading...</p>

        playerList = <PlayerListComponent players={@state.game.players} />

        if @state.game.winner
          winnerBlock = <h1>{ @state.game.winner.nick } has won!</h1>

        if @state.game.canJoin
          joinBlock = <div>
            <input type="text" ref="nick" placeholder="Your nick" />
            <button onClick={@onJoin}>Join game</button>
          </div>
        else if @state.game.waitingForPlayers
          joinBlock = <p>Waiting for more players to join</p>

        if @state.dice
          diceBlock = <Dice dice={@state.dice} />

        if @state.game.localPlayersTurn
          gambleBlock = <GambleComponent
              doGamble={@doGamble} doBullshit={@doBullshit} />

        if @state.game.lastGamble
          lastGambleBlock = <LastGambleComponent lastGamble={@state.game.lastGamble} />

        return <div>
                <button onClick={@props.handleGoToLobby}>Back</button>
                <h2>Round { @state.game.round }</h2>
                { playerList }
                { winnerBlock }
                { joinBlock }
                { diceBlock }
                { gambleBlock }
                { lastGambleBlock }
            </div>

    onJoin: ->
      nick = @refs.nick.getDOMNode().value.trim()
      GameActions.Join.send(@props.id, nick)

    doGamble: (value, quantity) ->
      GameActions.Gamble.send(@props.id, @state.secret, value, quantity)

    doBullshit: ->
      GameActions.Bullshit.send(@props.id, @state.secret)
})

module.exports = GameComponent
