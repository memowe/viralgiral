#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Time::HiRes 'time';

use_ok 'ViralGiral::Data';
my $model = ViralGiral::Data->new;

subtest 'Logger handling' => sub {
    my $rand = rand;
    $model->logger($rand);
    is $model->events->_est->logger => $rand, 'Correct logger set';
};

# Disable event logging for tests as events are tested in EventStore::Tiny
$model->logger(undef);

subtest 'Emptiness' => sub {
    ok $model->is_empty, 'Model is empty after creation';
    is $model->last_update => 0, 'No updates yet';
};

# Global test data
my ($e_id, $e_created);

subtest 'Entity handling' => sub {

    subtest Create => sub {

        # Add
        $e_id = $model->add_entity({answer => 42});

        # Check generated UUID
        ok defined($e_id), 'Generated ID is defined';
        like $e_id => qr/^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$/,
            'Generated ID looks like a UUID';
    };

    subtest Read => sub {

        subtest 'Nothing' => sub {

            # Try to retrieve an undefined entity
            ok not(defined $model->get_entity(undef)),
                'Undefined result (ID undefined)';

            # Try to retrieve a non-existant entity
            ok not(defined $model->get_entity(17)), 'Unknown entity';
        };

        subtest 'All entities' => sub {
            my $entities = $model->all_entities;
            ok defined($entities), 'Retrieved data is defined';
            is_deeply [keys %$entities] => [$e_id], 'Got the right ID';
            my $e_data = $entities->{$e_id};
        };

        subtest 'One entity' => sub {

            # Retrieve the only entity
            my $data = $model->get_entity($e_id);
            ok defined($data), 'Retrieved data is defined';
            is_deeply $data => $data, 'Retrieved the same data';

            # Check data details
            $e_created = $data->{created};
            ok time - $e_created < 0.1, 'Timestamp looks near';
            ok time - $e_created > 0, 'Timestamp looks different';
            is_deeply $data => {
                uuid    => $e_id,
                created => $e_created,
                users   => [],
                data    => {answer => 42},
            }, 'Correct data';
        };
    };

    subtest Update => sub {

        # Unknown entity exception
        throws_ok {$model->modify_entity(42, {foo => 42})}
            qr/Unknown entity with UUID '42'/,
            'Correct error message for unknown entity';

        # Update the only entity
        $model->modify_entity($e_id, {answer => 17});

        # Check entity list and retrieve
        my $entities = $model->all_entities;
        is_deeply [keys %$entities] => [$e_id], 'Entity ID list unchanged';

        # Check its data
        my $data = $model->get_entity($e_id);
        ok defined($data), 'Retrieved data is defined';
        is_deeply $data => {
            uuid    => $e_id,
            created => $e_created,
            users   => [],
            data    => {answer => 17},
        }, 'Correct modified data';
    };

    subtest Delete => sub {

        # Unknown entity exception
        throws_ok {$model->delete_entity(17)}
            qr/Unknown entity with UUID '17'/,
            'Correct error message for unknown entity';

        # Delete
        $model->delete_entity($e_id);
        is_deeply $model->all_entities => {}, 'No entities left';
    };
};

subtest 'User handling' => sub {

    # Prepare
    $e_id = $model->add_entity;
    my ($u1_id, $u1_created, $u2_id, $u2_created);

    subtest Create => sub {

        # Unknown entity exception
        throws_ok {$model->add_user(37, undef)}
            qr/Unknown entity with UUID '37'/,
            'Correct error message for unknown entity';

        # Unknow user reference exception
        throws_ok {$model->add_user($e_id, 42)}
            qr/Unknown user reference with UUID '42'/,
            'Correct error message for unknown user reference';

        # Add
        $u1_id = $model->add_user($e_id, undef);

        # Check generated ID
        ok defined($u1_id), 'Generated ID is defined';
        like $u1_id => qr/^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$/,
            'Generated ID looks like a UUID';

        # Add associated user
        $u2_id = $model->add_user($e_id, $u1_id, {foo => 42});

        # Check generated ID
        ok defined($u2_id), 'Generated ID is defined';
        like $u2_id => qr/^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$/,
            'Generated ID looks like a UUID';
    };

    subtest Read => sub {

        # Retrieve user lists
        is_deeply $model->get_entity($e_id)->{users} => [$u1_id, $u2_id],
            'Users belong to the entity';
        is_deeply [sort keys %{$model->all_users}] => [sort $u1_id, $u2_id],
            'Users created';

        subtest 'Nothing' => sub {

            # Try to retrieve an undefined user
            ok not(defined $model->get_user(undef)),
                'Undefined result (ID undefined)';

            # Try to retrieve a non-existant user
            ok not(defined $model->get_user(17)), 'Unknown user';
        };

        subtest 'Root user' => sub {

            # Retrieve user data
            my $user = $model->get_user($u1_id);
            ok defined($user), 'User data is defined';
            $u1_created = $user->{created};

            # Check user data
            ok time - $u1_created < 0.1, 'Timestamp looks near';
            ok time - $u1_created > 0, 'Timestamp looks different';
            is_deeply $user => {
                uuid        => $u1_id,
                created     => $u1_created,
                entity      => $e_id,
                reference   => undef,
                data        => {},
            }, 'Correct user data';
        };

        subtest 'Child user' => sub {

            # Retrieve user data
            my $user = $model->get_user($u2_id);
            ok defined($user), 'User data is defined';
            $u2_created = $user->{created};

            # Check user data
            ok time - $u2_created < 0.1, 'Timestamp looks near';
            ok time - $u2_created > 0, 'Timestamp looks different';
            is_deeply $user => {
                uuid        => $u2_id,
                created     => $u2_created,
                entity      => $e_id,
                reference   => $u1_id,
                data        => {foo => 42},
            }, 'Correct user data';
        };
    };

    subtest Update => sub {

        # Unknown user exception
        throws_ok {$model->modify_user(37, {foo => 42})}
            qr/Unknown user with UUID '37'/,
            'Correct error message (unknown user)';

        # Update
        $model->modify_user($u2_id, {foo => 17});

        # Check changes
        is_deeply $model->get_entity($e_id)->{users} => [$u1_id, $u2_id],
            'User list in entity unchanged';
        is_deeply $model->get_user($u2_id) => {
            uuid        => $u2_id,
            created     => $u2_created,
            entity      => $e_id,
            reference   => $u1_id,
            data        => {foo => 17},
        }, 'Correct user data';
    };

    subtest Delete => sub {

        # Unknown user exception
        throws_ok {$model->delete_user(42)}
            qr/Unknown user with UUID '42'/,
            'Correct error message (unknown user)';

        # Delete
        $model->delete_user($u2_id);
        is_deeply $model->get_entity($e_id)->{users} => [$u1_id],
            'User list in entity updated';
        is_deeply [keys %{$model->all_users}] => [$u1_id],
            'User list updated';
    };
};

done_testing;

__END__
