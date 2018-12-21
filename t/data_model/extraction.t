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

done_testing;

__END__
