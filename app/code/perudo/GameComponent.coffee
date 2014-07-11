React = require 'react'
Dice = require './Dice'

GameComponent = React.createClass({
    onEventPushed: (eventName, data) ->
        data = JSON.parse(data)
        player = data.player
        newState = {
            players: data.game.players
        }
        if player
            newState.player = player

        if @playerId
            newState.yourTurn = data.game.player_turn == @playerId

        if data.game.last_gamble
            [quantity, value] = data.game.last_gamble.split(',')
            newState.lastGamble = {
                quantity: parseInt(quantity),
                value: parseInt(value)
            }

        if data.game.round != @round
            # New round! get dice
            url = "/game/#{@gameId}/#{@secret}"
            $.getJSON(url, @setGameState)
            return

        @setState(newState)

    setGameState: (gameData) ->
        @gameId = gameData.game.id
        inProgress = if gameData.player then true else false
        yourTurn = false
        if inProgress
            dice = gameData.player.dice.split(",")
            dice = dice.map((d) -> parseInt(d))
            yourTurn = gameData.player.number == gameData.game.player_turn

        lastGamble = null
        if gameData.game.last_gamble
            [quantity, value] = gameData.game.last_gamble.split(',')
            lastGamble = {
                quantity: parseInt(quantity),
                value: parseInt(value)
            }

        @setState({
            inProgress: inProgress,
            dice: dice,
            player: gameData.player,
            players: gameData.game.players,
            canJoin: not inProgress,
            yourTurn: yourTurn,
            lastGamble: lastGamble,
            round: gameData.game.round})

    getInitialState: ->
        return {msg: 'No message yet'}

    componentWillMount: ->
        @round = @props.initialGame.game.round
        @gameId = @props.initialGame.game.id
        @secret = localStorage["game:#{@gameId}:secret"]
        @player = null
        if @props.initialGame.player
            @playerId = @props.initialGame.player.number
        @props.pusher.bind_all(@onEventPushed)
        @setGameState(@props.initialGame)

    render: ->
        playerNodes = @state.players.map((player) ->
            return <li key={player.nick}>{player.nick}</li>
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
            if @state.yourTurn
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
            @setGameState(data)
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
            # Do some state
            console.log data
        $.post(url, arg, onSuccess, "text")

    doBullshit: ->
        url = "/game/#{@gameId}/#{@secret}/do_turn"
        arg = "gamble=bullshit"
        onSuccess = (data) =>
            # Do some state
            console.log data
        $.post(url, arg, onSuccess, "text")
})

module.exports = GameComponent
