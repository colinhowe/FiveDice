class GameModel
  properties = [
    'id',
    'players',
    'localPlayer', # The player object for the local player
    'secret',
    'round',
    'currentPlayer', # The player whose turn it is
    'started', # Has the game started?
  ]

  GAME_WAITING_PLAYERS = 1
  GAME_STARTED = 2

  inProgress: ->
    return @status == GAME_STARTED

module.exports = GameModel
