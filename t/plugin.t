#!/usr/bin/env perl

use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Mojo;
use File::Temp 'tmpnam';

#--- Example web app ---
use Mojolicious::Lite;
use lib app->home->rel_file('../lib')->to_string;
plugin 'ViralGiral';
my $t = Test::Mojo->new;
$ENV{MOJO_LOG_LEVEL} = 'fatal';
#--- End of example web app ---

subtest 'Data' => sub {
    ok defined($t->app->viralgiral_data), 'viralgiral_data helper works';
    isa_ok $t->app->viralgiral_data => 'ViralGiral::Data', 'Data instance';
    is $t->app->viralgiral_data->data_filename
        => $t->app->home->rel_file('VG_data'),
        'Correct data filename';
};

#--- Fake action injection
package ViralGiral::Controller;
use Mojo::Base 'Mojolicious::Controller', -signatures;
sub xnorzft ($c) {$c->render(text => 'xnorfzt OK')}
package main;
#--- End of fake action ---

subtest 'Known route' => sub {
    $t->get_ok('/vg/xnorzft')->status_is(200)->content_is('xnorfzt OK');
};

subtest 'Unknown route' => sub {
    $t->get_ok('/foobelhaft')->status_is(404);
};

#--- Load ViralGiral plugin with configuration data ---
my $data_fn = tmpnam;
plugin ViralGiral => {
    data_filename   => $data_fn,
    prefix          => 'foobarbaz',
};
#--- End of config ---

#--- Fake action injection
package ViralGiral::Controller;
sub quux ($c) {$c->render(text => 'quux OK')}
package main;
#--- End of fake action ---

subtest 'Configured data' => sub {
    is $t->app->viralgiral_data->data_filename => $data_fn,
        'Correct data filename';
};

subtest 'Old known route' => sub {
    $t->get_ok('/xnorfzt')->status_is(404);
};

subtest 'Known configured route' => sub {
    $t->get_ok('/foobarbaz/quux')->status_is(200)->content_is('quux OK');
};

subtest 'Unknown configured route' => sub {
    $t->get_ok('/foobarbaz/foobelhaft')->status_is(404);
};

done_testing;
