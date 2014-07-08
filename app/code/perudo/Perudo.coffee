require 'pusher'

$ = require 'jquery'
React = require 'react'

template = require './perudo.jsx'
lobbyTemplate = require './lobby.jsx'

PerudoComponent = React.createClass({
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
            $.getJSON(url, @setGameState);
            return

        console.log newState
        @setState(newState)

    handleGoToLobby: (e) ->
        @props.handleGoToLobby()

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
            console.log 'setting player'
            console.log @playerId
        @props.pusher.bind_all(@onEventPushed)
        @setGameState(@props.initialGame)

    render: template.render

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

    render: lobbyTemplate.render

    onCreateGame: ->
        nick = @refs.nick.getDOMNode().value.trim()
        numPlayers = parseInt(@refs.numPlayers.getDOMNode().value.trim())
        @props.onCreateGame(nick=nick, numPlayers=numPlayers)

})

class PerudoGame

    constructor: (options) ->
        @el = options.el

        @pusher = new Pusher('fe78125e095d7477da6e');
        @loadLobby()
        # @channel = @pusher.subscribe('fivedice.game.2');

    loadLobby: () =>
        $.getJSON('/game/lobby', @lobbyLoaded)

    loadGame: (gameId) =>
        url = '/game/' + gameId
        secret = localStorage["game:#{gameId}:secret"]
        if secret
            url += "/#{secret}"
        $.getJSON(url, @gameLoaded);

    lobbyLoaded: (data) =>
        games = []
        for game in data.games
            games.push({
                key: game.id,
                status: game.status
            })

        React.unmountComponentAtNode(@el)
        @component = new LobbyComponent({
            onGameSelected: @loadGame,
            onCreateGame: @onCreateGame,
            games: games})
        React.renderComponent(@component, @el)

    gameLoaded: (data) =>
        @pusher.subscribe('fivedice.game.'+data.game.id)
        @component = PerudoComponent({
            handleGoToLobby: @loadLobby, initialGame: data,
            pusher: @pusher,
        })
        React.renderComponent(@component, @el)

    onCreateGame: (nick, numPlayers) =>
        url = "/game/new"
        args = {
            num_players: numPlayers,
            nick: nick
        }
        onSuccess = (data) =>
            # Record the game secret for later use
            localStorage["game:#{data.game.id}:secret"] = data.player.secret
            @loadLobby()

        $.post(url, args, onSuccess, "json")
        

module.exports =
    create: (options) -> new PerudoGame(options)
