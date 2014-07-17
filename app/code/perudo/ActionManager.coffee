class ActionManager
  constructor: ->
    @registry = {}
    @allActions = {}

  registerAction: (name) ->
    @allActions[name] = action = new Action(name)
    @registry[name] = []
    return action

  subscribe: (action, owner, callback) ->
    @registry[action.name].push([owner, callback])

  unsubscribe: (action, callback) ->
    callbacks = @registry[action.name]
    @registry[action.name] = callbacks.filter((owner, cb) -> cb != callback)

  send: (action, args) ->
    if action.name not of @allActions
      throw "Action #{action.name} not registered"
    if action.name not of @registry
      return
    for [owner, callback] in @registry[action.name]
      callback.apply(owner, args)

class Action
  constructor: (@name) ->

  send: (args...) ->
    manager_singleton.send(@, args)

  subscribe: (owner, callback) ->
    manager_singleton.subscribe(@, owner, callback)

  unsubscribe: (callback) ->
    manager_singleton.unsubscribe(@, callback)

manager_singleton = new ActionManager()

module.exports = manager_singleton
