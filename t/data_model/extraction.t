#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'ViralGiral::Data';
my $model = ViralGiral::Data->new;

# Disable event logging for tests as events are tested in EventStore::Tiny
$model->logger(undef);

# Preparation
my $e_id    = $model->add_entity;
my $u1_id   = $model->add_user($e_id, undef);
my $u2_id   = $model->add_user($e_id, $u1_id);
my $u3_id   = $model->add_user($e_id, $u2_id);
my $u4_id   = $model->add_user($e_id, $u2_id);

subtest 'Entity data per user' => sub {

    subtest 'No user' => sub {
        throws_ok {$model->get_entity_for_user(undef)}
            qr/Unknown user with UUID 'undef'/, 'UUID undefined';
        throws_ok {$model->get_entity_for_user(42)}
            qr/Unknown user with UUID '42'/, 'Unknown UUID';
    };

    my $e = $model->get_entity_for_user($u1_id);

    # Check data
    is_deeply $e => $model->get_entity($e_id), 'Correct entity data for u1';

    # The same
    is_deeply $model->get_entity_for_user($u2_id) => $e, 'Same entity (u2)';
    is_deeply $model->get_entity_for_user($u3_id) => $e, 'Same entity (u3)';
    is_deeply $model->get_entity_for_user($u4_id) => $e, 'Same entity (u4)';
};

subtest 'Predecessors' => sub {

    subtest 'Single' => sub {
        throws_ok {$model->get_predecessor(42)}
            qr/Unknown user with UUID '42'/, 'Invalid input UUID';
        is $model->get_predecessor($u1_id), undef, 'No predecessor';
        is_deeply $model->get_predecessor($u2_id), $model->get_user($u1_id),
            'Correct predecessor of u2';
        is_deeply $model->get_predecessor($u3_id), $model->get_user($u2_id),
            'Correct predecessor of u3';
        is_deeply $model->get_predecessor($u4_id), $model->get_user($u2_id),
            'Correct predecessor of u4';
    };

    subtest 'All' => sub {
        throws_ok {$model->get_all_predecessors(42)}
            qr/Unknown user with UUID '42'/, 'Invalid input UUID';
        is_deeply $model->get_all_predecessors($u1_id), [], 'No predecessor';
        is_deeply $model->get_all_predecessors($u2_id),
            [map $model->get_user($_) => $u1_id], 'Correct predecessors of u2';
        is_deeply $model->get_all_predecessors($u3_id),
            [map $model->get_user($_) => $u2_id, $u1_id],
            'Correct predecessors of u3';
        is_deeply $model->get_all_predecessors($u4_id),
            [map $model->get_user($_) => $u2_id, $u1_id],
            'Correct predecessors of u4';
    };
};

subtest 'Successors' => sub {

    subtest 'Direct' => sub {
        throws_ok {$model->get_successors(42)}
            qr/Unknown user with UUID '42'/, 'Invalid input UUID';
        is_deeply $model->get_successors($u1_id),
            [$model->get_user($u2_id)], 'One successor (u1)';
        is_deeply $model->get_successors($u2_id),
            [map $model->get_user($_) => $u3_id, $u4_id], 'Two successors (u2)';
        is_deeply $model->get_successors($u3_id), [], 'No successor (u3)';
        is_deeply $model->get_successors($u4_id), [], 'No successor (u4)';
    };

    subtest 'All' => sub {
        throws_ok {$model->get_all_successors(42)}
            qr/Unknown user with UUID '42'/, 'Invalid input UUID';
        is_deeply $model->get_all_successors($u1_id),
            [map $model->get_user($_) => $u2_id, $u3_id, $u4_id],
            'Correct successors (u1)';
        is_deeply $model->get_all_successors($u2_id),
            [map $model->get_user($_) => $u3_id, $u4_id],
            'Correct successors (u2)';
        is_deeply $model->get_all_successors($u3_id), [], 'No successor (e3)';
        is_deeply $model->get_all_successors($u4_id), [], 'No successor (e4)';
    };
};

done_testing;

__END__
