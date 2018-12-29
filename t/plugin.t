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

subtest 'Info action' => sub {
    $t->get_ok('/vg/info')->status_is(200)
        ->text_is(h1 => 'ViralGiral is running!', 'Correct headline')
        ->content_like(qr/
            perl                .*  $^V .*
            ViralGiral          .*  $ViralGiral::VERSION .*
            Mojolicious         .*  $Mojolicious::VERSION .*
            EventStore::Tiny    .*  $EventStore::Tiny::VERSION .*
        /sx, 'Correct info data');
};

#--- Load ViralGiral plugin with configuration data ---
my $data_fn = tmpnam;
plugin ViralGiral => {
    data_filename   => $data_fn,
    prefix          => 'foobarbaz',
};
#--- End of config ---

subtest 'Configured data' => sub {
    is $t->app->viralgiral_data->data_filename => $data_fn,
        'Correct data filename';
};

subtest 'Configured info action' => sub {
    $t->get_ok('/foobarbaz/info')->status_is(200)
        ->text_is(h1 => 'ViralGiral is running!', 'Correct headline');
};

subtest 'Unknown configured route' => sub {
    $t->get_ok('/foobarbaz/foobelhaft')->status_is(404);
};

subtest 'Shortener' => sub {
    is $t->app->shorten(       123 => 5)    =>      '123';
    is $t->app->shorten(      1234 => 5)    =>     '1234';
    is $t->app->shorten(     12345 => 5)    =>    '12345';
    is $t->app->shorten(    123456 => 5)    =>    '12345...';
    is $t->app->shorten(   1234567 => 5)    =>    '12345...';
    is $t->app->shorten(  12345678 => 6)    =>   '123456...';
    is $t->app->shorten( 123456789     )    => '12345678...',
        'Correct default: 8';
};

done_testing;
