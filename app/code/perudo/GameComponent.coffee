$ = require 'jquery'
React = require 'react'

Dice = require './Dice'
GameStore = require './GameStore'

GameComponent = React.createClass({
    onEventPushed: (eventName, data) ->
      console.log 'pushed'
      console.log data
      if typeof data == "object"
        console.log 'early bail'
        return
      data = JSON.parse(data)
      # TODO round changes
      currentRound = @game.round
      new GameStore().updateGameWithNewData(@game, data)
      console.log '-- got game'
      console.log @game
      if @game.round != currentRound
        console.log 'Need to get new dice'

      @syncState()

    syncState: ->
        @gameId = @game.id

        inProgress = @game.inProgress()
        yourTurn = false
        if @localPlayerId and inProgress
            yourTurn = @localPlayerId == @game.currentPlayer.id

        lastGamble = null
        if @game.last_gamble
            [quantity, value] = gameData.game.last_gamble.split(',')
            lastGamble = {
                quantity: parseInt(quantity),
                value: parseInt(value)
            }

        if @localPlayerId
          localPlayer = @game.players[@localPlayerId]
        newState = {
            inProgress: inProgress,
            dice: @dice,
            localPlayer: localPlayer,
            currentPlayer: @game.currentPlayer,
            players: (player for _, player of @game.players),
            canJoin: not inProgress,
            yourTurn: yourTurn,
            lastGamble: lastGamble,
            round: @game.round
        }
        @setState(newState)

    getInitialState: ->
        return {msg: 'No message yet'}

    componentWillMount: ->
        @game = @props.game
        @dice = @props.dice
        @round = @game.round
        @gameId = @game.id
        @localPlayerId = @props.localPlayerId
        @secret = localStorage["game:#{@gameId}:secret"]
        @props.pusher.bind_all(@onEventPushed)
        @syncState()

    render: ->
        playerNodes = @state.players.map((player) ->
          <li key={player.nick}>{player.nick}</li>
        )
        if @state.canJoin
            joinBlock = <div>
                <input type="text" ref="nick" placeholder="Your nick" />
                <button onClick={@onJoin}>Join game</button>
            </div>
        else
            joinBlock = null

        diceBlock = null
        turnBlock = null
        if @state.inProgress
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
                { joinBlock }
                { diceBlock }
                { lastGambleBlock }
                { turnBlock }
            </div>

    onJoin: ->
        nick = @refs.nick.getDOMNode().value.trim()
        onSuccess = (data) =>
            @secret = data.player.secret
            localStorage["game:#{data.game.id}:secret"] = @secret
            @syncState()
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
