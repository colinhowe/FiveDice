$ = require 'jquery'
GameModel = require './GameModel'
PlayerModel = require './PlayerModel'

class GameStore
  fetchById: (id, gameSecret, onSuccess) ->
    url = '/game/' + id
    if gameSecret
        url += "/#{gameSecret}"
    $.getJSON(url, (data) =>
      game = new GameModel()
      @_parseGame(game, gameSecret, data)
      if data.player
        dice = data.player.dice.split(",")
        dice = dice.map((d) -> parseInt(d))
        localPlayerId = data.player.number
      onSuccess(game, dice, localPlayerId)
    )

  updateGameWithNewData: (game, data) ->
    @_parseGame(game, null, data)

    ###
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
        $.getJSON(url, @syncState)
        return

    @setState(newState)###

  _parseGame: (game, gameSecret, data) ->
    console.log 'parsing data'
    console.log data

    players = {}
    console.log typeof data
    for player in data.game.players
      player = @_parsePlayer(player)
      players[player.id] = player

    if data.player?
      # If there is a player in the data then that is the current player and
      # contains more information about the state so use that instead
      localPlayer = @_parsePlayer(data.player)
      players[localPlayer.id] = localPlayer
    
    game.id = data.game.id
    game.players = players
    game.localPlayer = localPlayer
    if gameSecret
      game.secret = gameSecret
    game.round = data.game.round
    game.currentPlayer = players[data.game.player_turn]
    game.status = data.game.status

  _parsePlayer: (playerData) ->
    return new PlayerModel(playerData.number, playerData.nick)

module.exports = GameStore
