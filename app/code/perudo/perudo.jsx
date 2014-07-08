React = require('react');
Dice = require('./Dice');

module.exports = {
    // See: http://facebook.github.io/react/docs/tutorial.html
    render: function() {
        var playerNodes = this.state.players.map(function(player) {
            return <li key={player.nick}>{player.nick}</li>
        });
        if (this.state.canJoin) {
            joinBlock = <div>
                <input type="text" ref="nick" placeholder="Your nick" />
                <button onClick={this.onJoin}>Join game</button>
            </div>
        } else {
            joinBlock = null;
        }

        diceBlock = null;
        turnBlock = null;
        if (this.state.inProgress) {
            diceBlock = <Dice dice={this.state.dice} />
            if (this.state.yourTurn) {
                turnBlock = <div>
                    <input ref="quantity" type="number" placeholder="number of dice" />
                    <input ref="value" type="number" placeholder="value of dice" />
                    <button onClick={this.doGamble}>Gamble</button>
                    <button onClick={this.doBullshit}>Call Bullshit</button>
                </div>
            }
        }

        lastGambleBlock = null;
        if (this.state.lastGamble) {
            lastGambleBlock = <div>
                <p>Last gamble was {this.state.lastGamble.quantity} {this.state.lastGamble.value}s</p>
            </div>
        }

        return <div>
                <button onClick={this.props.handleGoToLobby}>Back</button>
                <ul>{ playerNodes }</ul>
                <h2>Round { this.state.round }</h2>
                { joinBlock }
                { diceBlock }
                { lastGambleBlock }
                { turnBlock }
            </div>
    }
};
