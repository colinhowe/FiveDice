$ = require 'jquery'
React = require 'react'

Dice = require './Dice'
GameStore = require './GameStore'

LastGambleComponent = React.createClass({
  render: ->
    return <div>
        <p>Last gamble was {@props.lastGamble.quantity} {@props.lastGamble.value}s</p>
    </div>
})

PlayerListComponent = React.createClass({
  render: ->
    players = (player for _, player of @props.players)
    playerNodes = players.map((player) ->
      <li key={player.nick}>{player.nick}</li>
    )
    return <ul>{ playerNodes }</ul>
})

GambleComponent = React.createClass({
  render: ->
    <div>
      <input ref="quantity" type="number" placeholder="number of dice" />
      <input ref="value" type="number" placeholder="value of dice" />
      <button onClick={@doGamble}>Gamble</button>
      <button onClick={@doBullshit}>Call Bullshit</button>
    </div>

  doGamble: ->
    value = parseInt(@refs.value.getDOMNode().value.trim())
    quantity = parseInt(@refs.quantity.getDOMNode().value.trim())
    @props.doGamble(value, quantity)
})

GameComponent = React.createClass({
    onEventPushed: (eventName, data) ->
      if typeof data == "object"
        return
      data = JSON.parse(data)

      currentRound = @state.game.round
      currentStatus = @state.game.status
      new GameStore().updateGameWithNewData(@state.game, data)
      gameJustStarted = @state.game.status != currentStatus and @state.game.inProgress()
      if @state.game.round != currentRound or gameJustStarted
        new GameStore().fetchNewDice(@state.game, @gotNewDice)
      else
        @syncState()

    gotNewDice: (dice) ->
      @dice = dice
      @syncState()

    syncState: ->
        newState = {
            dice: @dice,
            loading: false,
            game: @state.game
        }
        @setState(newState)

    getInitialState: ->
        return {
          loading: true
        }

    componentDidMount: ->
      gameId = @props.id
      secret = localStorage["game:#{gameId}:secret"]
      @setProps({secret: secret})

      new GameStore().fetchById(gameId, secret, @gameLoaded)

    gameLoaded: (game, dice, localPlayerId) ->
      @setState({game: game})
      @localPlayerId = localPlayerId
      @dice = dice

      channel = "fivedice.game.#{@props.id}"
      pusher = @props.pusher
      pusher.subscribe(channel)
      pusher.bind_all(@onEventPushed)

      @syncState()

    componentWillUnmount: ->
      channel = "fivedice.game.#{@props.id}"
      @props.pusher.unsubscribe(channel)

    render: ->
        if @state.loading
          return <p>Loading...</p>

        playerList = <PlayerListComponent players={@state.game.players} />

        if @state.game.winner
          winnerBlock = <h1>{ @state.game.winner.nick } has won!</h1>

        if @state.game.canJoin()
          joinBlock = <div>
            <input type="text" ref="nick" placeholder="Your nick" />
            <button onClick={@onJoin}>Join game</button>
          </div>
        else if @state.game.waitingForPlayers()
          joinBlock = <p>Waiting for more players to join</p>

        if @state.dice
            diceBlock = <Dice dice={@state.dice} />

        if @state.game.localPlayersTurn()
          gambleBlock = <GambleComponent
              doGamble={@doGamble} doBullshit={@doBullshit} />

        if @state.game.lastGamble
          lastGambleBlock = <LastGambleComponent lastGamble={@state.game.lastGamble} />

        return <div>
                <button onClick={@props.handleGoToLobby}>Back</button>
                <h2>Round { @state.game.round }</h2>
                { playerList }
                { winnerBlock }
                { joinBlock }
                { diceBlock }
                { gambleBlock }
                { lastGambleBlock }
            </div>

    onJoin: ->
      nick = @refs.nick.getDOMNode().value.trim()
      onSuccess = (data) =>
        secret = data.player.secret
        @setProps({secret: secret})
        @state.game.secret = secret
        localStorage["game:#{data.game.id}:secret"] = secret

        gs = new GameStore()
        gs.updateGameWithNewData(@state.game, data)
        gs.fetchNewDice(@state.game, @gotNewDice)
        
      args = {
        nick: nick
      }
      url = "/game/#{@props.id}/join"
      $.post(url, args, onSuccess, "json")

    doGamble: (value, quantity) ->
        url = "/game/#{@props.id}/#{@props.secret}/do_turn"
        arg = "gamble=#{quantity},#{value}"
        onSuccess = (data) =>
          new GameStore().updateGameWithNewData(@state.game, data)
          @syncState()
        $.post(url, arg, onSuccess, "json")

    doBullshit: ->
        url = "/game/#{@props.id}/#{@props.secret}/do_turn"
        arg = "gamble=bullshit"
        onSuccess = (data) =>
            # Do some state
        $.post(url, arg, onSuccess, "text")
})

module.exports = GameComponent
