$ = require 'jquery'

GameActions = require './GameActions'

GAME_WAITING_PLAYERS = 1
GAME_STARTED = 2
GAME_ENDED = 3

class GameStore

  constructor: ->
    @subscribers = []
    @secretSubscribers = []
    GameActions.Gamble.subscribe(@, @onGamble)
    GameActions.Bullshit.subscribe(@, @onBullshit)
    GameActions.Join.subscribe(@, @onJoin)

  _parseDice: (dice) ->
    dice = dice.split(",")
    dice = dice.map((d) -> parseInt(d))
    return dice

  fetchById: (id, gameSecret, onSuccess) ->
    url = '/game/' + id
    if gameSecret
        url += "/#{gameSecret}"
    $.getJSON(url, (data) =>
      game = {}
      @_parseGame(game, data)
      if data.player?.dice
        dice = @_parseDice(data.player.dice)
      if data.player
        localPlayerId = data.player.number
      onSuccess(game, dice, localPlayerId)
    )

  _parseGame: (game, data) ->
    players = {}
    for player in data.game.players
      players[player.number] = @_parsePlayer(player)

    if data.player?
      # If there is a player in the data then that is the current player and
      # contains more information about the state so use that instead
      game.localPlayer = @_parsePlayer(data.player)

    game.id = data.game.id
    game.players = players
    if data.player?.secret
      @_secretSent(data.player.secret)
    game.round = data.game.round
    game.status = data.game.status

    if data.game.last_gamble == "bullshit"
      game.lastGamble = null
    else if data.game.last_gamble
      [quantity, value] = data.game.last_gamble.split(',')
      game.lastGamble = {
        quantity: parseInt(quantity),
        value: parseInt(value)
      }
    else
      game.lastGamble = null

    if data.game.player_won
      game.winner = players[data.game.player_won]

    game.updateState = ->
      if @localPlayer
        @players[@localPlayer.id] = @localPlayer
      game.currentPlayer = players[data.game.player_turn]
      
      @inProgress = @status == GAME_STARTED
      @waitingForPlayers = @status == GAME_WAITING_PLAYERS
      @canJoin = @status == GAME_WAITING_PLAYERS and not @localPlayer
      @localPlayersTurn = @currentPlayer == @localPlayer and @inProgress
    game.updateState()

  _parsePlayer: (playerData) ->
    return {id: playerData.number, nick: playerData.nick}

  onGamble: (gameId, secret, value, quantity) ->
    url = "/game/#{gameId}/#{secret}/do_turn"
    arg = "gamble=#{quantity},#{value}"
    $.post(url, arg, @_gameChanged, "json")

  onBullshit: (gameId, secret) ->
      url = "/game/#{gameId}/#{secret}/do_turn"
      arg = "gamble=bullshit"
      $.post(url, arg, @_gameChanged, "json")

  _gameChanged: (data) =>
    game = {}
    @_parseGame(game, data)

    for subscriber in @subscribers
      subscriber(game)

  _secretSent: (gameId, secret) =>
    for subscriber in @secretSubscribers
      subscriber(gameId, secret)

  subscribe: (cb) ->
    @subscribers.push(cb)

  unsubscribe: (cb) ->
    @subscribers = @subscribers.filter((cb2) -> cb2 != cb)

  subscribeSecret: (cb) ->
    @secretSubscribers.push(cb)

  unsubscribeSecret: (cb) ->
    @secretSubscribers = @secretSubscribers.filter((cb2) -> cb2 != cb)

  watch: (pusher, gameId) ->
    channelName = "fivedice.game.#{gameId}"
    channel = pusher.subscribe(channelName)
    channel.bind_all(@_onEventPushed)

  unwatch: (pusher, gameId) ->
    channel = "fivedice.game.#{gameId}"
    pusher.unsubscribe(channel)

  _onEventPushed: (eventName, data) =>
    if typeof data == "object"
      return
    data = JSON.parse(data)

    @_gameChanged(data)

  onJoin: (gameId, nick) ->
    args = {
      nick: nick
    }
    url = "/game/#{gameId}/join"
    cb = (data) =>
      @_gameChanged(data)
    $.post(url, args, cb, "json")


module.exports = new GameStore()
