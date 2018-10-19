use v5.20.0;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ViralGiral',
    AUTHOR              => 'Mirko Westermeier <mirko@westermeier.de>',
    VERSION_FROM        => 'lib/ViralGiral.pm',
    LICENSE             => 'mit',
    MIN_PERL_VERSION    => '5.20.0',
    PREREQ_PM           => {
        'Clone'             => '0.39',
        'EventStore::Tiny'  => '0.51',
        'Mojolicious'       => '7.93',
        'UUID::Tiny'        => '1.04',
    },
    TEST_REQUIRES => {
        'Test::Exception'   => '0.43',
    },
    META_MERGE          => {resources => {
        bugtracker => 'http://github.com/memowe/viralgiral/issues',
        repository => 'http://github.com/memowe/viralgiral',
    }},
    test                => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'}
);
