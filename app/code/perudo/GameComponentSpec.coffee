$ =  require 'jquery'
React = require 'react/addons'
ReactTestUtils = React.addons.TestUtils

GambleComponent = require './GambleComponent'

describe('Gamble component', ->
  it('Handles valid input and invokes callback', ->
    gambled = false
    doGamble = (value, quantity) ->
      expect(value).toEqual(5)
      expect(quantity).toEqual(2)
      gambled = true

    bullshitted = false
    doBullshit = ->
      bullshitted = true

    component = <GambleComponent doGamble={doGamble} doBullshit={doBullshit} />
    ReactTestUtils.renderIntoDocument(component)

    $(component.refs.quantity.getDOMNode()).val('2')
    $(component.refs.value.getDOMNode()).val('5')
    ReactTestUtils.Simulate.click(component.refs.gambleButton.getDOMNode())
    expect(gambled).toEqual(true)

    ReactTestUtils.Simulate.click(component.refs.bullshitButton.getDOMNode())
    expect(bullshitted).toEqual(true)
  )

  it('Does not invoke callback for invalid input', ->
    gambled = false
    doGamble = (value, quantity) ->
      gambled = true

    doBullshit = ->

    component = <GambleComponent doGamble={doGamble} doBullshit={doBullshit} />
    ReactTestUtils.renderIntoDocument(component)

    $(component.refs.quantity.getDOMNode()).val('apple')
    $(component.refs.value.getDOMNode()).val('berry')
    ReactTestUtils.Simulate.click(component.refs.gambleButton.getDOMNode())
    expect(gambled).toEqual(false)
  )
)
