$ = require 'jquery'
React = require 'react'

Dice = require './Dice'
GameStore = require './GameStore'

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
    onEventPushed: (eventName, data) ->
      if typeof data == "object"
        return
      data = JSON.parse(data)

      currentRound = @state.game.round
      currentStatus = @state.game.status

      @_syncGame(data)

      if @state.game.round != currentRound or @state.game.status != currentStatus
        new GameStore().fetchById(@state.game.id, @state.game.secret, @gotNewDice)

    _syncGame: (data) ->
      game = new GameStore().updateGameWithNewData(@state.game, data)
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

      new GameStore().fetchById(gameId, secret, @gameLoaded)

    gameLoaded: (game, dice, localPlayerId) ->
      @setState({loading: false, game: game, dice: dice})

      channelName = "fivedice.game.#{@props.id}"
      pusher = @props.pusher
      channel = pusher.subscribe(channelName)
      channel.bind_all(@onEventPushed)

    componentWillUnmount: ->
      channel = "fivedice.game.#{@props.id}"
      @props.pusher.unsubscribe(channel)

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
      onSuccess = (data) =>
        secret = data.player.secret
        @setState({secret: secret})
        @state.game.secret = secret
        localStorage["game:#{data.game.id}:secret"] = secret

        @_syncGame(data)
        new GameStore().fetchById(@state.game.id, @state.game.secret, @gotNewDice)
        
      args = {
        nick: nick
      }
      url = "/game/#{@props.id}/join"
      $.post(url, args, onSuccess, "json")

    doGamble: (value, quantity) ->
        url = "/game/#{@props.id}/#{@state.secret}/do_turn"
        arg = "gamble=#{quantity},#{value}"
        $.post(url, arg, @_syncGame, "json")

    doBullshit: ->
        url = "/game/#{@props.id}/#{@state.secret}/do_turn"
        arg = "gamble=bullshit"
        onSuccess = (data) =>
            # Do some state
        $.post(url, arg, onSuccess, "text")
})

module.exports = GameComponent
