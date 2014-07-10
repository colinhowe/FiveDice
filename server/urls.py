from django.conf.urls import patterns, url

from server import views


urlpatterns = patterns(
    '',
    url(r'^app/.*$', views.index),
    url(r'^game/lobby$', views.game_list),
    url(r'^game/rankings$', views.game_rankings),

    url(r'^game/new$', views.game_new),

    url(r'^game/(?P<pk>[0-9]+)$', views.game_state),
    url(r'^game/(?P<pk>[0-9]+)/join$', views.game_join),

    url(r'^game/(?P<pk>[0-9]+)/(?P<secret>[0-9a-f]+)$', views.game_player_state, name="game-player-state"),
    url(r'^game/(?P<pk>[0-9]+)/(?P<secret>[0-9a-f]+)/do_turn$', views.game_do_turn),
    url(r'^game/(?P<pk>[0-9]+)/(?P<secret>[0-9a-f]+)/quit$', views.game_quit),
)
