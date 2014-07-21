React = require 'react'

GambleComponent = React.createClass({
  render: ->
    <div>
      <input ref="quantity" type="number" placeholder="number of dice" />
      <input ref="value" type="number" placeholder="value of dice" />
      <button ref="gambleButton" onClick={@doGamble}>Gamble</button>
      <button ref="bullshitButton" onClick={@doBullshit}>Call Bullshit</button>
    </div>

  doGamble: ->
    value = parseInt(@refs.value.getDOMNode().value.trim())
    quantity = parseInt(@refs.quantity.getDOMNode().value.trim())
    if value and quantity
      @props.doGamble(value, quantity)

  doBullshit: ->
    @props.doBullshit()
})

module.exports = GambleComponent
