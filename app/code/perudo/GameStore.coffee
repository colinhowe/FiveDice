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
      if data.player?.dice
        dice = data.player.dice.split(",")
        dice = dice.map((d) -> parseInt(d))
      if data.player
        localPlayerId = data.player.number
      onSuccess(game, dice, localPlayerId)
    )

  fetchNewDice: (game, onSuccess) ->
    url = "/game/#{game.id}/#{game.secret}"
    $.getJSON(url, (data) =>
      @_parseGame(game, null, data)
      if data.player
        dice = data.player.dice.split(",")
        dice = dice.map((d) -> parseInt(d))
        onSuccess(dice)
    )

  updateGameWithNewData: (game, data) ->
    # Create a new game and copy local data from the old game as we
    # don't always get given that in updates
    newGame = new GameModel()
    newGame.localPlayer = game.localPlayer
    newGame.secret = game.secret
    @_parseGame(newGame, null, data)
    return newGame

  _parseGame: (game, gameSecret, data) ->
    players = {}
    for player in data.game.players
      player = @_parsePlayer(player)
      players[player.id] = player

    if data.player?
      # If there is a player in the data then that is the current player and
      # contains more information about the state so use that instead
      game.localPlayer = @_parsePlayer(data.player)

    if game.localPlayer
      players[game.localPlayer.id] = game.localPlayer
    
    game.id = data.game.id
    game.players = players
    if gameSecret
      game.secret = gameSecret
    game.round = data.game.round
    game.currentPlayer = players[data.game.player_turn]
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

  _parsePlayer: (playerData) ->
    return new PlayerModel(playerData.number, playerData.nick)

module.exports = GameStore
