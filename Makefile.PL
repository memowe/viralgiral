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
        'Mojolicious'   => '7.93',
        'UUID::Tiny'    => '1.04',
    },
    META_MERGE          => {resources => {
        bugtracker => 'http://github.com/memowe/viralgiral/issues',
        repository => 'http://github.com/memowe/viralgiral',
    }},
);
