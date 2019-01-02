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

subtest 'Entity details' => sub {

    subtest 'Unknown entity' => sub {
        $t->get_ok('/introspection/entity/krzlbfoo')->status_is(404);
    };

    subtest 'First entity' => sub {
        my $entity = $data->get_entity($e1);
        $t->get_ok("/introspection/entity/$e1")->status_is(200)
            ->text_is(h1 => 'Entity ' . $t->app->shorten($e1));

        my $base_data_rows = $t->tx->res->dom('#entity-base-data li');
        is scalar(@$base_data_rows) => 2, 'Got two base data rows';
        like $base_data_rows->[0]->all_text => qr/^ UUID: \s+ $e1 $/x,
            'Correct UUID row';
        my $exdrx = quotemeta strftime '%F %T' => localtime $entity->{created};
        like $base_data_rows->[1]->all_text =>
            qr/^ Created: \s+ $exdrx $/x, 'Correct created row';

        subtest 'Data' => sub {
            my $thead = $t->tx->res->dom->at('#entity-data thead');
            like $thead->all_text => qr/^ \s* Field \s+ Data \s* $/x,
                'Correct table head';
            my $data_rows = $t->tx->res->dom('#entity-data tbody tr');
            my $data = $entity->{data};
            is scalar(@$data_rows) => scalar(keys %$data),
                'Correct data field count';

            for my $i (0 .. keys(%$data) - 1) {
                my $key = (sort keys %$data)[$i];
                my $row = $data_rows->[$i];
                subtest "Row $i" => sub {
                    is $row->at('th')->text => $key, 'Correct field th';
                    is $row->at('td code')->text => pp($data->{$key}),
                        'Correct data stringification';
                };
            }
        };

        subtest 'Users' => sub {
            my $thead = $t->tx->res->dom->at('#entity-users thead');
            like $thead->all_text => qr/^ \s* User \s+ UUID
                \s+ Created \s+ Data \s* $/x, 'Correct table head';
            is scalar(@{$t->tx->res->dom('#entity-users tbody tr')}) => 0,
                'No user rows';
        };
    };

    subtest 'Second entity' => sub {
        my $entity = $data->get_entity($e2);
        $t->get_ok("/introspection/entity/$e2")->status_is(200)
            ->text_is(h1 => 'Entity ' . $t->app->shorten($e2));

        my $base_data_rows = $t->tx->res->dom('#entity-base-data li');
        is scalar(@$base_data_rows) => 2, 'Got two base data rows';
        like $base_data_rows->[0]->all_text => qr/^ UUID: \s+ $e2 $/x,
            'Correct UUID row';
        my $exdrx = quotemeta strftime '%F %T' => localtime $entity->{created};
        like $base_data_rows->[1]->all_text =>
            qr/^ Created: \s+ $exdrx $/x, 'Correct created row';

        subtest 'Data' => sub {
            my $thead = $t->tx->res->dom->at('#entity-data thead');
            like $thead->all_text => qr/^ \s* Field \s+ Data \s* $/x,
                'Correct table head';
            my $data_rows = $t->tx->res->dom('#entity-data tbody tr');
            my $data = $entity->{data};
            is scalar(@$data_rows) => scalar(keys %$data),
                'Correct data field count';

            for my $i (0 .. keys(%$data) - 1) {
                my $key = (sort keys %$data)[$i];
                my $row = $data_rows->[$i];
                subtest "Row $i" => sub {
                    is $row->at('th')->text => $key, 'Correct field th';
                    is $row->at('td code')->text => pp($data->{$key}),
                        'Correct data stringification';
                };
            }
        };

        subtest 'Users' => sub {
            my $thead = $t->tx->res->dom->at('#entity-users thead');
            like $thead->all_text => qr/^ \s* User \s+ UUID
                \s+ Created \s+ Data \s* $/x, 'Correct table head';

            my $user_rows = $t->tx->res->dom('#entity-users tbody tr');
            is scalar(@$user_rows) => 2, 'Two user rows found';

            for my $i (0 .. $#{$entity->{users}}) {
                my $uuid = $entity->{users}[$i];
                my $user = $t->app->viralgiral_data->get_user($uuid);
                my $row  = $user_rows->[$i];
                subtest "User $i" => sub {

                    # UUID / user link
                    my $th_link = $row->at('th a');
                    is $th_link->text => $t->app->shorten($uuid),
                        'Correct UUID';
                    is $th_link->attr('href') => "/introspection/user/$uuid",
                        'Correct user page link';

                    # Created
                    is $row->find('td')->[0]->text =>
                        strftime('%F %T' => localtime $user->{created}),
                        'Correct creation time';

                    # Data
                    is $row->at('td code')->text => pp($user->{data}),
                        'Correct data stringification';
                };
            }
        };
    };
};

done_testing;
