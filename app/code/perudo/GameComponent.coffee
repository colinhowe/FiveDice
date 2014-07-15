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
    playerNodes = @props.players.map((player) ->
      <li key={player.nick}>{player.nick}</li>
    )
    return <ul>{ playerNodes }</ul>
})

GambleComponent = React.createClass({
  render: ->
    <div>
      <input ref="quantity" type="number" placeholder="number of dice" />
      <input ref="value" type="number" placeholder="value of dice" />
      <button onClick={@props.doGamble}>Gamble</button>
      <button onClick={@props.doBullshit}>Call Bullshit</button>
    </div>
})

GameComponent = React.createClass({
    onEventPushed: (eventName, data) ->
      if typeof data == "object"
        return
      data = JSON.parse(data)

      currentRound = @game.round
      currentStatus = @game.status
      new GameStore().updateGameWithNewData(@game, data)
      gameJustStarted = @game.status != currentStatus and @game.inProgress()
      if @game.round != currentRound or gameJustStarted
        new GameStore().fetchNewDice(@game, @gotNewDice)
      else
        @syncState()

    gotNewDice: (dice) ->
      @dice = dice
      @syncState()

    syncState: ->
        inProgress = @game.inProgress()
        yourTurn = false
        if @localPlayerId and inProgress
            yourTurn = @localPlayerId == @game.currentPlayer.id

        if @localPlayerId
          localPlayer = @game.players[@localPlayerId]
        newState = {
            inProgress: inProgress,
            dice: @dice,
            localPlayer: localPlayer,
            currentPlayer: @game.currentPlayer,
            players: (player for _, player of @game.players),
            canJoin: @game.waitingForPlayers(),
            yourTurn: yourTurn,
            lastGamble: @game.lastGamble,
            round: @game.round,
            winner: @game.winner,
            loading: false
        }
        @setState(newState)

    getInitialState: ->
        return {
          loading: true
        }

    componentDidMount: ->
      gameId = @props.id
      secret = localStorage["game:#{gameId}:secret"]
      @setProps({secret: secret})

      new GameStore().fetchById(gameId, secret, @gameLoaded)

    gameLoaded: (game, dice, localPlayerId) ->
      @game = game
      @localPlayerId = localPlayerId
      @dice = dice

      channel = "fivedice.game.#{@props.id}"
      pusher = @props.pusher
      pusher.subscribe(channel)
      pusher.bind_all(@onEventPushed)

      @syncState()

    componentWillUnmount: ->
      channel = "fivedice.game.#{@props.id}"
      @props.pusher.unsubscribe(channel)

    render: ->
        if @state.loading
          return <p>Loading...</p>

        playerList = <PlayerListComponent players={@state.players} />

        if @state.winner
          winnerBlock = <h1>{ @state.winner.nick } has won!</h1>

        if @state.canJoin and not @state.localPlayer
          joinBlock = <div>
            <input type="text" ref="nick" placeholder="Your nick" />
            <button onClick={@onJoin}>Join game</button>
          </div>
        else if @state.canJoin
          joinBlock = <p>Waiting for more players to join</p>

        if @state.dice
            diceBlock = <Dice dice={@state.dice} />
            if @state.localPlayer == @state.currentPlayer
                gambleBlock = <GambleComponent
                  doGamble={@doGamble} doBullshit={@doBullshit} />

        if @state.lastGamble
          lastGambleBlock = <LastGambleComponent lastGamble={@state.lastGamble} />

        return <div>
                <button onClick={@props.handleGoToLobby}>Back</button>
                <h2>Round { @state.round }</h2>
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
        @setProps({secret: secret})
        @game.secret = secret
        localStorage["game:#{data.game.id}:secret"] = secret

        gs = new GameStore()
        gs.updateGameWithNewData(@game, data)
        gs.fetchNewDice(@game, @gotNewDice)
        
      args = {
        nick: nick
      }
      url = "/game/#{@props.id}/join"
      $.post(url, args, onSuccess, "json")

    doGamble: ->
        value = parseInt(@refs.value.getDOMNode().value.trim())
        quantity = parseInt(@refs.quantity.getDOMNode().value.trim())
        url = "/game/#{@props.id}/#{@props.secret}/do_turn"
        arg = "gamble=#{quantity},#{value}"
        onSuccess = (data) =>
          new GameStore().updateGameWithNewData(@game, data)
          @syncState()
        $.post(url, arg, onSuccess, "json")

    doBullshit: ->
        url = "/game/#{@props.id}/#{@props.secret}/do_turn"
        arg = "gamble=bullshit"
        onSuccess = (data) =>
            # Do some state
        $.post(url, arg, onSuccess, "text")
})

module.exports = GameComponent
