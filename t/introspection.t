#!/usr/bin/env perl

use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Mojo;
use File::Temp 'tmpnam';
use POSIX 'strftime';
use Data::Dump 'pp';

my $data_fn = tmpnam;

#--- Example web app ---
use Mojolicious::Lite;
use lib app->home->rel_file('../lib')->to_string;
plugin ViralGiral => {
    prefix          => '',
    data_filename   => $data_fn,
    introspection   => 1,
};
my $t = Test::Mojo->new;
$ENV{MOJO_LOG_LEVEL} = 'fatal';
#--- End of example web app ---

#--- Example data ---
my $data = $t->app->viralgiral_data;
ok $data->is_empty, 'No data found yet';
my $e1 = $data->add_entity({foo => 17, bar => 42});
my $e2 = $data->add_entity({foo => 37, bar => 66});
my $u1 = $data->add_user($e2, undef, {baz => 17, quux => 42});
my $u2 = $data->add_user($e2, $u1, {baz => 42, quux => 37});
ok not($data->is_empty), 'Data store filled successfully';
#--- End of example data ---

subtest 'Entity listing' => sub {
    $t->get_ok('/introspection')->status_is(200)
        ->text_is(h1 => 'Entity listing');
    my $thead = $t->tx->res->dom->at('thead');
    like $thead->all_text => qr/^ \s* Entity\ UUID \s* Created \s*
        Data \s* User\ count \s* $/x, 'Correct table head';
    my $rows = $t->tx->res->dom('tbody tr');
    is $rows->size => 2, 'Found two tbody rows';

    subtest 'First entity' => sub {
        my $entity = $data->get_entity($e1);
        my @cells = @{$rows->[0]->children};
        is scalar(@cells) => 4, 'Found four cells';

        my $elink = $cells[0]->at('a');
        is $elink->attr('href') => "/introspection/entity/$e1",
            'Correct entity URL';
        is $elink->text => $t->app->shorten($e1), 'Correct link text';
        is $cells[1]->text => strftime('%F %T' => localtime $entity->{created}),
            'Correct time stamp';
        is $cells[2]->at('pre code')->text => pp($entity->{data}),
            'Correct data dump';
        is $cells[3]->text => scalar(@{$entity->{users}}), 'Correct user count';
    };

    subtest 'Second entity' => sub {
        my $entity = $data->get_entity($e2);
        my @cells = @{$rows->[1]->children};
        is scalar(@cells) => 4, 'Found four cells';

        my $elink = $cells[0]->at('a');
        is $elink->attr('href') => "/introspection/entity/$e2",
            'Correct entity URL';
        is $elink->text => $t->app->shorten($e2), 'Correct link text';
        is $cells[1]->text => strftime('%F %T' => localtime $entity->{created}),
            'Correct time stamp';
        is $cells[2]->at('pre code')->text => pp($entity->{data}),
            'Correct data dump';
        is $cells[3]->text => scalar(@{$entity->{users}}), 'Correct user count';
    };
};

done_testing;
