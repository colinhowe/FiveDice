ActionManager = require './ActionManager'

module.exports =
  Gamble: ActionManager.registerAction('gamble')
  Bullshit: ActionManager.registerAction('bullshit')
  Join: ActionManager.registerAction('join')
