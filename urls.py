from django.conf.urls import patterns

# from django.contrib import admin
# admin.autodiscover()

from server import urls as server_urls

urlpatterns = patterns('',
)

urlpatterns += server_urls.urlpatterns
