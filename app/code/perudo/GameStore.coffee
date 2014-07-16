$ = require 'jquery'

GAME_WAITING_PLAYERS = 1
GAME_STARTED = 2
GAME_ENDED = 3

class GameStore

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
      @_parseGame(game, gameSecret, data)
      if data.player?.dice
        dice = @_parseDice(data.player.dice)
      if data.player
        localPlayerId = data.player.number
      onSuccess(game, dice, localPlayerId)
    )

  updateGameWithNewData: (game, data) ->
    # Create a new game and copy local data from the old game as we
    # don't always get given that in updates
    newGame = {}
    newGame.localPlayer = game.localPlayer
    newGame.secret = game.secret
    @_parseGame(newGame, null, data)
    return newGame

  _parseGame: (game, gameSecret, data) ->
    players = {}
    for player in data.game.players
      players[player.id] = @_parsePlayer(player)

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

    game.inProgress = game.status == GAME_STARTED
    game.waitingForPlayers = game.status == GAME_WAITING_PLAYERS
    game.canJoin = game.status == GAME_WAITING_PLAYERS and not game.localPlayer
    game.localPlayersTurn = game.currentPlayer == game.localPlayer and game.inProgress

  _parsePlayer: (playerData) ->
    return {id: playerData.number, nick: playerData.nick}

module.exports = GameStore
