React = require('react');
LobbyGameRow = require('./LobbyGameRow');

module.exports = {
    render: function() {
        var gameNodes = this.state.games.map(function (game){
            return <LobbyGameRow
                key={game.key}
                game={game}
                onGameSelected={ this.handleGameChange }/>
        }, this);
        return <div>
            <input type="text" placeholder="Your name" ref="nick" />
            <input type="number" placeholder="Number of players" ref="numPlayers" />
            <button onClick={this.onCreateGame}>Create Game</button>
            <div>{ gameNodes }</div>
        </div>
    }
};
