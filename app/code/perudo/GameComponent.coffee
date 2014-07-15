$ = require 'jquery'
React = require 'react'

Dice = require './Dice'
GameStore = require './GameStore'

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
        @gameId = @game.id

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
            winner: @game.winner
        }
        @setState(newState)

    getInitialState: ->
        return {}

    componentWillMount: ->
        @game = @props.game
        @dice = @props.dice
        @round = @game.round
        @gameId = @game.id
        @localPlayerId = @props.localPlayerId
        @secret = localStorage["game:#{@gameId}:secret"]

        @channel = "fivedice.game.#{@gameId}"
        @pusher = @props.pusher
        @pusher.subscribe(@channel)
        @props.pusher.bind_all(@onEventPushed)

        @syncState()

    componentWillUnmount: ->
        @props.pusher.unsubscribe(@channel)


    render: ->
        playerNodes = @state.players.map((player) ->
          <li key={player.nick}>{player.nick}</li>
        )
        if @state.canJoin and not @state.localPlayer
          joinBlock = <div>
            <input type="text" ref="nick" placeholder="Your nick" />
            <button onClick={@onJoin}>Join game</button>
          </div>
        else if @state.canJoin
          joinBlock = <p>Waiting for more players to join</p>

        diceBlock = null
        turnBlock = null
        winnerBlock = null
        
        if @state.winner
          winnerBlock = <h1>{ @state.winner.nick } has won!</h1>

        if @state.dice
            diceBlock = <Dice dice={@state.dice} />
            if @state.localPlayer == @state.currentPlayer
                turnBlock = <div>
                    <input ref="quantity" type="number" placeholder="number of dice" />
                    <input ref="value" type="number" placeholder="value of dice" />
                    <button onClick={@doGamble}>Gamble</button>
                    <button onClick={@doBullshit}>Call Bullshit</button>
                </div>

        lastGambleBlock = null
        if @state.lastGamble
            lastGambleBlock = <div>
                <p>Last gamble was {@state.lastGamble.quantity} {@state.lastGamble.value}s</p>
            </div>

        return <div>
                <button onClick={@props.handleGoToLobby}>Back</button>
                <ul>{ playerNodes }</ul>
                <h2>Round { @state.round }</h2>
                { winnerBlock }
                { joinBlock }
                { diceBlock }
                { lastGambleBlock }
                { turnBlock }
            </div>

    onJoin: ->
      nick = @refs.nick.getDOMNode().value.trim()
      onSuccess = (data) =>
        @secret = data.player.secret
        @game.secret = @secret
        localStorage["game:#{data.game.id}:secret"] = @secret

        gs = new GameStore()
        gs.updateGameWithNewData(@game, data)
        gs.fetchNewDice(@game, @gotNewDice)
        
      args = {
        nick: nick
      }
      url = "/game/#{@gameId}/join"
      $.post(url, args, onSuccess, "json")

    doGamble: ->
        value = parseInt(@refs.value.getDOMNode().value.trim())
        quantity = parseInt(@refs.quantity.getDOMNode().value.trim())
        url = "/game/#{@gameId}/#{@secret}/do_turn"
        arg = "gamble=#{quantity},#{value}"
        onSuccess = (data) =>
          new GameStore().updateGameWithNewData(@game, data)
          @syncState()
        $.post(url, arg, onSuccess, "json")

    doBullshit: ->
        url = "/game/#{@gameId}/#{@secret}/do_turn"
        arg = "gamble=bullshit"
        onSuccess = (data) =>
            # Do some state
        $.post(url, arg, onSuccess, "text")
})

module.exports = GameComponent
