#!/usr/bin/env perl
use Mojolicious::Lite;
use lib app->home->rel_file('lib')->to_string;
plugin ViralGiral => {introspection => 1};
app->start;
