import json
import re

from django.http import HttpResponse, HttpResponseBadRequest
from django.core.urlresolvers import reverse
from django.shortcuts import render_to_response

from server import (
    WAITING_FOR_PLAYERS, RUNNING, OVER, split_ints, jsonified_exceptions)
from server.models import Game, Player
from server import message


def _json_response(data):
    return HttpResponse(json.dumps(data), content_type="application/json")


def _json_error(msg):
    return HttpResponse(
        json.dumps({"error": msg}), content_type="application/json")


def _push_game_state_to_clients(request, game, event):
    message.send(
        'game.' + str(game.id),
        event,
        json.dumps({"game": game.to_dict()}),
        request.POST.get('socket_id', None))


@jsonified_exceptions
def game_list(request):
    if request.method.upper() not in ["GET"]:
        return HttpResponseBadRequest()

    return _json_response({
        "games": [
            g.to_dict()
            for g in Game.objects.filter(
                status__in=[WAITING_FOR_PLAYERS, RUNNING]).order_by('id')
        ]
    })


@jsonified_exceptions
def game_rankings(request):
    if request.method.upper() not in ["GET"]:
        return HttpResponseBadRequest()

    return _json_error("Not implemented yet.")


@jsonified_exceptions
def game_new(request):
    if request.method.upper() not in ["POST"]:
        return HttpResponseBadRequest()

    num_players = request.POST.get("num_players", None)
    nick = request.POST.get("nick", None)

    if not num_players:
        return _json_error("'num_players' field is required.")
    if not nick:
        return _json_error("'nick' field is required.")

    game = Game(num_players=num_players)
    game.save()

    player = Player(nick=nick, secret=Player.generate_secret(), game=game)
    player.save()

    return _json_response({
        "game": game.to_dict(),
        "player": player.to_dict(show_secret=True),
        "game_url": request.build_absolute_uri(reverse(
            "game-player-state",
            kwargs={"pk": game.pk, "secret": player.secret})),
    })


@jsonified_exceptions
def game_state(request, pk):
    if request.method.upper() not in ["GET"]:
        return HttpResponseBadRequest()

    game = Game.objects.get(pk=pk)

    return _json_response({"game": game.to_dict()})


@jsonified_exceptions
def game_join(request, pk):
    if request.method.upper() not in ["POST"]:
        return HttpResponseBadRequest()

    game = Game.objects.get(pk=pk)

    if game.status != WAITING_FOR_PLAYERS:
        return _json_error("Sorry mate, that game has started")

    nick = request.POST.get("nick", None)
    if not nick:
        return _json_error("'nick' field is required.")

    # It is not allowed to use a nick from another player in the same game. Even
    # if that player is marked LOST or QUIT.
    if game.player_set.filter(nick=nick).exists():
        return _json_error("'nick' %s already taken" % nick)

    player = Player(
        nick=nick, secret=Player.generate_secret(), game=game,
        number=game.generate_next_player_number())
    player.save()

    if game.player_set.count() >= game.num_players:
        game.status = RUNNING
        game.save()

        game.roll_all_dice()

        _push_game_state_to_clients(request, game, "game_join")

    return _json_response({
        "game": game.to_dict(),
        "player": player.to_dict(show_secret=True),
        "game_url": request.build_absolute_uri(reverse(
            "game-player-state",
            kwargs={"pk": game.pk, "secret": player.secret})),
    })


@jsonified_exceptions
def game_player_state(request, pk, secret):
    if request.method.upper() not in ["GET"]:
        return HttpResponseBadRequest()

    game = Game.objects.get(pk=pk)
    player = game.playing_players.get(secret=secret)

    player_kwargs = {}
    player_kwargs['show_dice'] = game.status == RUNNING

    return _json_response({
        "game": game.to_dict(),
        "player": player.to_dict(**player_kwargs)
    })


@jsonified_exceptions
def game_do_turn(request, pk, secret):
    if request.method.upper() not in ["POST"]:
        return HttpResponseBadRequest()

    game = Game.objects.get(pk=pk)
    player = game.playing_players.get(secret=secret)

    if game.player_turn != player.number:
        return _json_error("It's not your turn!")

    gamble = request.POST.get('gamble', None).lower()

    if not gamble:
        return _json_error("You going to play or what?")

    if gamble in ["bullshit", "exact"]:
        if not game.last_gamble:
            return _json_error(
                "You can't call %s on the first turn of the round!" % gamble)
        else:
            getattr(game, "do_" + gamble)()
            if game.status != OVER:
                game.roll_all_dice()
    elif not re.match(r'^[0-9]+,[1-6]$', gamble):
        return _json_error(
            "'gamble' format is invalid. Format is '11,6' to "
            "mean 'eleven sixes'")
    else:
        num_dice, value_called = split_ints(gamble)

        if num_dice < 0:
            return _json_error("Number of dice must be positive")
        elif value_called < 1 or value_called > 6:
            return _json_error("Value of dice must be between 1 and 6")

        if not game.last_gamble:
            game.do_gamble(gamble)
        else:
            cur_num_dice, cur_value_called = split_ints(game.last_gamble)

            if not (value_called > cur_value_called or num_dice > cur_num_dice):
                return _json_error(
                    "Either the number of dice or the value must go up!")
            else:
                game.do_gamble(gamble)

    _push_game_state_to_clients(request, game, "game_do_turn")

    return _json_response({"game": game.to_dict()})


@jsonified_exceptions
def game_quit(request, pk, secret):
    if request.method.upper() not in ["POST"]:
        return HttpResponseBadRequest()

    game = Game.objects.get(pk=pk)
    player = game.playing_players.get(secret=secret)
    player.do_quit()

    _push_game_state_to_clients(request, game, "game_quit")

    return _json_response(True)

def index(request):
    return render_to_response('index.html', {})
