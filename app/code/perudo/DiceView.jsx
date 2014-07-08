module.exports = function () {
    var i = 0
    var diceNodes = this.props.dice.map(function(die) {
        unicodeMap = {
            1: "\u2680",
            2: "\u2681",
            3: "\u2682",
            4: "\u2683",
            5: "\u2684",
            6: "\u2685"
        }
        unicodeDie = unicodeMap[die]
        return <span className="die" key={i++}>{unicodeDie}</span>
    });
    return <ul>{diceNodes}</ul>
}
