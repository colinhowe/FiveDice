React = require 'react'

dieToUnicodeMap = {
  1: "\u2680",
  2: "\u2681",
  3: "\u2682",
  4: "\u2683",
  5: "\u2684",
  6: "\u2685"
}

Dice = React.createClass({
    render: ->
      i = 0
      diceNodes = @props.dice.map((die) ->
          unicodeDie = dieToUnicodeMap[die]
          return <span className="die" key={i++}>{unicodeDie}</span>
      )
      return <ul>{diceNodes}</ul>
})

module.exports = Dice
