require 'pusher'

$ = require 'jquery'
React = require 'react'
hasher = require 'hasher'
crossroads = require 'crossroads'

LobbyComponent = require './LobbyComponent'
GameComponent = require './GameComponent'

class PerudoManager

    constructor: (options) ->
        @el = options.el

        @pusher = new Pusher('fe78125e095d7477da6e')
        # @channel = @pusher.subscribe('fivedice.game.2');

        @_initRoutes()

    _initRoutes: () ->
        crossroads.addRoute('', @loadLobby)
        crossroads.addRoute('game/{id}/', @loadGame)
        crossroads.ignoreState = true
         
        # Setup hasher
        parseHash = (newHash, oldHash) =>
          crossroads.parse(newHash)

        hasher.initialized.add(parseHash) # parse initial hash
        hasher.changed.add(parseHash) # parse hash changes
        hasher.init() # start listening for history change
        
    _setUrlHash: (hash) =>
        hasher.setHash(hash)

    goToLobby: =>
        console.log 'setting hash'
        @_setUrlHash('')

    goToGame: (id) =>
        @_setUrlHash("game/#{id}")

    loadLobby: =>
        $.getJSON('/game/lobby', @lobbyLoaded)

    loadGame: (gameId) =>
        url = '/game/' + gameId
        secret = localStorage["game:#{gameId}:secret"]
        if secret
            url += "/#{secret}"
        $.getJSON(url, @gameLoaded)

    lobbyLoaded: (data) =>
        games = []
        for game in data.games
            games.push({
                key: game.id,
                status: game.status
            })

        React.unmountComponentAtNode(@el)
        @component = new LobbyComponent({
            onGameSelected: @goToGame,
            onCreateGame: @onCreateGame,
            games: games})
        React.renderComponent(@component, @el)

    gameLoaded: (data) =>
        @pusher.subscribe('fivedice.game.'+data.game.id)
        @component = GameComponent({
            handleGoToLobby: @goToLobby,
            initialGame: data,
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

module.exports = PerudoManager
