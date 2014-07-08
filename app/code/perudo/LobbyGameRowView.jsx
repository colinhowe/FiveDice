React = require('react');

module.exports = {
    render: function() {
        joinType = "Spectate"
        if (this.props.secret) {
            joinType = "Play"
        }
        gameState = this.props.game.status
        gameStateMsg = {
            1: "Waiting for players",
            2: "In progress"
        }[gameState]
        return <div><button onClick={ this.handleClick }>
            {joinType} Game { this.props.game.key } {gameStateMsg}
        </button></div>
    }
};
