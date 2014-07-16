import os
import random

from django.db import models

from server import (
    GAME_STATUSES, WAITING_FOR_PLAYERS, OVER,
    PLAYER_STATUSES, PLAYING, QUIT, LOST,
    split_ints)


def xstr(s):
    if s is None:
        return ''
    else:
        return str(s)


class Game(models.Model):
    # The number of player who must join before this game will begin
    num_players = models.SmallIntegerField()

    # Denormalised field to easily look up games waiting for players
    status = models.SmallIntegerField(
        choices=GAME_STATUSES, default=WAITING_FOR_PLAYERS)

    round = models.IntegerField(default=1)
    last_gamble = models.CharField(max_length=32, blank=True, null=True)
    last_loser = models.SmallIntegerField(blank=True, null=True, default=None)
    last_quitter = models.SmallIntegerField(blank=True, null=True, default=None)

    # Using the player turn number here rather than foreign key references.
    # Slightly slower maybe but it is a relative value and avoids accidentally
    # referencing players who are not meant to be in this game.
    player_turn = models.SmallIntegerField(default=1)
    player_won = models.SmallIntegerField(blank=True, null=True, default=None)

    @property
    def playing_players(self):
        return self.player_set.all()

    @property
    def ordered_players(self):
        return self.playing_players.order_by('number')

    @property
    def current_player(self):
        return self.playing_players.get(number=self.player_turn)

    @property
    def count_dice_for_all_players(self):
        totals = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}

        for p in self.playing_players:
            dice = split_ints(p.dice)
            for v in dice:
                totals[v] += 1

        return totals

    def generate_next_player_number(self):
        p = list(self.ordered_players)
        return p[-1].number + 1 if p else 1

    def roll_all_dice(self):
        for player in self.player_set.filter(status=PLAYING):
            player.roll_dice()

    def sibling_player(self, forwards=True):
        length = self.playing_players.count()
        qs = self.playing_players.order_by("number" if forwards else "-number")
        pp = [p for p in qs]

        if length <= 1:
            return None

        # Loop through the entire list, but only once
        for i in range(length):
            p = pp[i]

            if p.number == self.player_turn:
                # Next one, but wrap the list
                return pp[(i + 1) % length]

        return (self.player_turn % self.num_players) + 1

    def next_player(self):
        return self.sibling_player()

    def prev_player(self):
        return self.sibling_player(forwards=False)

    def do_gamble(self, gamble):
        self.last_gamble = gamble
        self.player_turn = self.next_player().number
        self.save()

    def do_exact(self):
        player = self.current_player
        num_dice, value_called = split_ints(self.last_gamble)
        totals = self.count_dice_for_all_players

        if totals[value_called] == num_dice:
            loser = self.prev_player()
            self.tally_round(player, loser, "exact", winner_gains_die=True)
        else:
            winner = self.prev_player()
            self.tally_round(winner, player, "exact")

    def do_bullshit(self):
        player = self.current_player
        num_dice, value_called = split_ints(self.last_gamble)
        totals = self.count_dice_for_all_players

        if totals[value_called] < num_dice:
            loser = self.prev_player()
            self.tally_round(player, loser, "bullshit")
        else:
            winner = self.prev_player()
            self.tally_round(winner, player, "bullshit")

    def tally_round(self, winner, loser, gamble, winner_gains_die=False):
        loser.lost_round()

        if winner_gains_die:
            winner.gain_a_die()

        alive_players = self.player_set.filter(status=PLAYING)
        if alive_players.count() == 1:
            self.player_won = winner.number
            self.last_loser = loser.number
            self.last_gamble = gamble  # Log the winning gamble, for history
            self.status = OVER
        else:
            self.round += 1
            self.last_gamble = ""
            self.last_loser = loser.number
            if loser.status == PLAYING:
                self.player_turn = loser.number
            else:
                self.player_turn = winner.number
        self.save()

    def to_dict(self):
        return {
            "id": self.id,
            "num_players": self.num_players,
            "status": self.status,
            "round": self.round,
            "last_gamble": self.last_gamble,
            "last_loser": self.last_loser,
            "last_quitter": self.last_quitter,
            "player_turn": self.player_turn,
            "player_won": self.player_won,
            "players": [p.to_dict() for p in self.ordered_players]
        }

    def __str__(self):
        return '#' + str(self.id)


class Player(models.Model):
    """
    This object is best thought of as Player Game State. It is a combination
    of all three and simplifies the architecture somewhat. There is no sign-up,
    registration, or login with this architecture. Just supply a nick and you
    are in (assuming the game isn't full).
    """
    nick = models.CharField(max_length=32)
    number = models.SmallIntegerField(default=1)
    secret = models.CharField(max_length=64)
    game = models.ForeignKey(Game)
    dice = models.CommaSeparatedIntegerField(max_length=32, default="0,0,0,0,0")

    # Denormalised field to make finding forfeiters, winners and losers easier
    status = models.SmallIntegerField(choices=PLAYER_STATUSES, default=PLAYING)

    @staticmethod
    def generate_secret():
        return os.urandom(16).encode('hex')

    def roll_dice(self):
        num_dice = len(split_ints(self.dice))
        self.dice = ",".join([
            str(random.randint(1, 6))
            for i in range(num_dice)])
        self.save()

    def lost_round(self):
        dice = split_ints(self.dice)

        if len(dice) <= 1:
            self.dice = ""
            self.status = LOST
        else:
            self.dice = ",".join(map(str, dice[:-1]))
        self.save()

    def gain_a_die(self):
        dice = split_ints(self.dice)

        if len(dice) < 5:
            self.dice = ",".join(map(str, dice + [1]))
            self.save()

    def do_quit(self):
        self.status = QUIT
        self.save()

        self.game.last_quitter = self.number
        self.game.save()

    def to_dict(self, show_dice=False, show_secret=False):
        data = {
            "nick": self.nick,
            "number": self.number,
        }
        if show_dice:
            data["dice"] = self.dice
        if show_secret:
            data["secret"] = self.secret
        return data

    def __str__(self):
        return '#' + str(self.id) + ': ' + ', '.join([
            xstr(self.number),
            xstr(self.nick)
        ])
