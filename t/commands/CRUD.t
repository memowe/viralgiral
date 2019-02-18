#!/usr/bin/env perl

#--- Example app ---
use Mojolicious::Lite;
use lib map app->home->rel_file($_)->to_string =>
    qw(../lib ../../Test-Mojo-CommandOutputRole/lib);
use File::Temp 'tmpnam';
plugin ViralGiral => {data_filename => scalar tmpnam};
my $t = Test::Mojo->new->with_roles('Test::Mojo::CommandOutputRole');
$ENV{MOJO_LOG_LEVEL} = 'fatal';
#--- End of example app ---

#--- Example data ---
use POSIX 'strftime';
my $model = $t->app->viralgiral_data;
my $e1_id = $model->add_entity({foo => 'Ford'});
my $e2_id = $model->add_entity({foo => 'Zaphod'});
my $e1_ts = $model->get_entity($e1_id)->{created};
my $e2_ts = $model->get_entity($e2_id)->{created};
my $e1_dt = strftime '%F %T' => localtime $e1_ts;
my $e2_dt = strftime '%F %T' => localtime $e2_ts;
my $u1_id = $model->add_user($e2_id, undef, {bar => 'Hector'});
my $u2_id = $model->add_user($e2_id, $u1_id, {bar => 'Willie'});
my $u1_ts = $model->get_user($u1_id)->{created};
my $u2_ts = $model->get_user($u2_id)->{created};
my $u1_dt = strftime '%F %T' => localtime $u1_ts;
my $u2_dt = strftime '%F %T' => localtime $u2_ts;
#--- End of example data ---

use Mojo::Base -strict, -signatures;
use Test::More;
use Test::Mojo;
use Data::Dump 'dump';

my %usage = (
    entity => <<'USAGE',
Usage: APPLICATION vg_entity [OPTIONS] [UUID]

    ./app vg_entity UUID
    ./app vg_entity --list --sort=name
    ./app vg_entity --create "name => 'Foo', color => 'white'"
    ./app vg_entity --update "answer => 42" UUID
    ./app vg_entity --delete UUID

Runmode list (--list [--sort X] [--show Y] [UUID])

    - List all entities sorted by creation time.
    - List all entities sorted by data field "foo" with --sort foo.
    - Explicitly add data field "bar" to listing with --show bar.
    - Complete dump of all data of the entity when a UUID is given.
    - The list runmode is default, so it doesn't need to be typed.

Runmode create (--create DATA_STRING)

    - Create a new entity, the created UUID is printed back.
    - Interprete the given DATA_STRING as the new data hash.
    - Print the UUID of the created entity.

Runmode update (--update DATA_STRING UUID)

    - Update the entity with the given UUID.
    - Use the DATA_STRING to update single data hash values.

Runmode delete (--delete UUID)

    - Delete the entity with the given UUID. (Caution!)
USAGE
    user => <<'USAGE',
Usage: APPLICATION vg_user [OPTIONS] [UUID]

    ./app vg_user UUID
    ./app vg_user --list --sort=name
    ./app vg_user --create EUID "name => 'Foo', color => 'white'"
    ./app vg_user --update "answer => 42" UUID
    ./app vg_user --delete UUID

Runmode list (--list [--sort X] [--show Y] [UUID])

    - List all users sorted by creation time.
    - List all users sorted by data field "foo" with --sort foo.
    - Explicitly add data field "bar" to listing with --show bar.
    - Complete dump of all data of the user when a UUID is given.
    - The list runmode is default, so it doesn't need to be typed.

Runmode create (--create EUID DATA_STRING)

    - Create a new user, the created UUID is printed back.
    - Interprete the given DATA_STRING as the new data hash.
    - Print the UUID of the created user.

Runmode update (--update DATA_STRING UUID)

    - Update the user with the given UUID.
    - Use the DATA_STRING to update single data hash values.

Runmode delete (--delete UUID)

    - Delete the user with the given UUID. (Caution!)
USAGE
);

subtest Entity => sub {
    $t->command_output(vg_entity => ['help'] => $usage{entity},
        'Correct usage message');

    subtest 'Ambiguous run mode' => sub {
        $t->command_output(vg_entity => [qw(-l --delete foo)] =>
            qr/^Ambiguous options '-l --delete foo'!\s+\Q$usage{entity}\E$/,
            'Correct disambiguation error for "-l --delete foo"');
        $t->command_output(vg_entity => [qw(-u --list -c bar)] =>
            qr/^Ambiguous options '-u --list -c bar'!\s+\Q$usage{entity}\E$/,
            'Correct disambiguation error for "-u --list -c bar"');
    };

    subtest List => sub {

        subtest All => sub {
            $t->command_output(vg_entity => ['-l'] =>
                "Entity $e2_id | $e2_dt, 2 user(s)\n"
              . "Entity $e1_id | $e1_dt, 0 user(s)\n",
                'Correct entity listing');
            $t->command_output(vg_entity => [qw(--list --show=foo)] =>
                "Entity $e2_id | $e2_dt, 2 user(s) | foo: \"Zaphod\"\n"
              . "Entity $e1_id | $e1_dt, 0 user(s) | foo: \"Ford\"\n",
                'Correct entity listing with foo');
            $t->command_output(vg_entity => [qw(-l --sort=foo)] =>
                "Entity $e1_id | $e1_dt, 0 user(s)\n"
              . "Entity $e2_id | $e2_dt, 2 user(s)\n",
                'Correct entity listing sorted by foo');
        };

        subtest Thing => sub {
            $t->command_output(vg_entity => ['--list', $e2_id] =>
                "Entity $e2_id | $e2_dt, 2 user(s)\n"
              . 'Data: ' . dump($model->get_entity($e2_id)->{data}) . "\n"
              . "Users:\n"
              . "User $u1_id | $u1_dt\n"
              . "User $u2_id | $u2_dt\n",
                'Correct entity dump');
        };
    };

    subtest Create => sub {

        subtest 'No data' => sub {
            my $entity_count = keys %{$model->all_entities};

            $t->command_output(vg_entity => ['--create'] => sub ($output) {
                ok $output =~ /^New entity with UUID '(\S+)' created\.$/,
                    'Correct output text format';
                my $new_id = $1;
                is scalar(keys %{$model->all_entities}) => $entity_count + 1,
                    'Entity count increased by one';
                my $e = $model->get_entity($new_id);
                ok defined($e), 'Got a new entity';
                is_deeply $e->{data} => {}, 'No data set';
            });
        };

        subtest 'With data' => sub {

            subtest Malformed => sub {
                $t->command_output(vg_entity => ['-c', 'xnorfzt'] =>
                    "Malformed data: xnorfzt\n", 'Bareword');
                $t->command_output(vg_entity => ['-c', '42'] =>
                    "Malformed data: 42\n", 'Scalar value');
            };

            subtest 'Correct hash data' => sub {

                my $entity_count = keys %{$model->all_entities};
                $t->command_output(vg_entity => ['-c', "a => 42"] => sub ($o) {
                    ok $o =~ /^New entity with UUID '(\S+)' created\.$/,
                        'Correct output text format';
                    my $new_id = $1;
                    is scalar(keys %{$model->all_entities}) =>
                        $entity_count + 1,
                        'Entity count increased by one';
                    my $e = $model->get_entity($new_id);
                    ok defined($e), 'Got a new entity';
                    is_deeply $e->{data} => {a => 42}, 'Correct data';
                }, 'Plain hash syntax');

                $entity_count = keys %{$model->all_entities};
                $t->command_output(vg_entity =>
                ['-c', "{b => 17, c => {answer => 42}}"] =>
                sub ($o) {
                    ok $o =~ /^New entity with UUID '(\S+)' created\.$/,
                        'Correct output text format';
                    my $new_id = $1;
                    is scalar(keys %{$model->all_entities}) =>
                        $entity_count + 1,
                        'Entity count increased by one';
                    my $e = $model->get_entity($new_id);
                    ok defined($e), 'Got a new entity';
                    is_deeply $e->{data} =>
                        {b => 17, c => {answer => 42}},
                        'Correct data';
                }, 'Hash syntax with surrounding braces');
            };
        };
    };

    subtest Update => sub {
        ok 1; # TODO
    };

    subtest Delete => sub {
        ok 1; # TODO
    };
};

subtest User => sub {
    $t->command_output(vg_user => ['help'] => $usage{user},
        'Correct usage message');

    subtest 'Ambiguous run mode' => sub {
        $t->command_output(vg_user => [qw(-l --delete foo)] =>
            qr/^Ambiguous options '-l --delete foo'!\s+\Q$usage{user}\E$/,
            'Correct disambiguation error for "-l --delete foo"');
        $t->command_output(vg_user => [qw(-u --list -c bar)] =>
            qr/^Ambiguous options '-u --list -c bar'!\s+\Q$usage{user}\E$/,
            'Correct disambiguation error for "-u --list -c bar"');
    };

    subtest List => sub {

        subtest All => sub {
            $t->command_output(vg_user => ['-l'] =>
                "User $u2_id | $u2_dt, "
                . "entity $e2_id, parent $u1_id\n"
              . "User $u1_id | $u1_dt, entity $e2_id\n",
                'Correct user listing');
            $t->command_output(vg_user => [qw(--list --show=bar)] =>
                "User $u2_id | $u2_dt, "
                . "entity $e2_id, parent $u1_id | bar: \"Willie\"\n"
              . "User $u1_id | $u1_dt, entity $e2_id | bar: \"Hector\"\n",
                'Correct user listing with foo');
            $t->command_output(vg_user => [qw(-l --sort=bar)] =>
                "User $u1_id | $u1_dt, entity $e2_id\n"
              . "User $u2_id | $u2_dt, "
                . "entity $e2_id, parent $u1_id\n",
                'Correct user listing sorted by foo');
        };

        subtest Thing => sub {
            $t->command_output(vg_user => ['--list', $u2_id] =>
                "User $u2_id | $u2_dt, "
                . "entity $e2_id, parent $u1_id\n"
              . 'Data: ' . dump($model->get_user($u2_id)->{data}) . "\n",
                'Correct user dump');
        };
    };

    subtest Create => sub {

        subtest 'No matching entity' => sub {
            $t->command_output(vg_user => ['--create'] => $usage{entity},
                'No entity UUID given');
            $t->command_output(vg_user => ['--create', '17'] =>
                "Unknown entity '17'.\n", 'Unknown entity given');
        };

        subtest 'No data' => sub {
            my $user_count = keys %{$model->all_users};

            $t->command_output(vg_user => ['--create', $e1_id] => sub ($o) {
                ok $o =~ /^New user with UUID '(\S+)' created\.$/,
                    'Correct output text format';
                my $new_id = $1;
                is scalar(keys %{$model->all_users}) => $user_count + 1,
                    'Entity count increased by one';
                my $e = $model->get_user($new_id);
                ok defined($e), 'Got a new user';
                is_deeply $e->{data} => {}, 'No data set';
            });
        };

        subtest 'With data' => sub {

            subtest Malformed => sub {
                $t->command_output(vg_user => ['-c', $e1_id, 'xnorfzt'] =>
                    "Malformed data: xnorfzt\n", 'Bareword');
                $t->command_output(vg_user => ['-c', '42'] =>
                    "Malformed data: 42\n", 'Scalar value');
            };

            subtest 'Correct hash data' => sub {

                my $user_count = keys %{$model->all_users};
                $t->command_output(vg_user => ['-c', $e1_id, "a => 42"] =>
                sub ($o) {
                    ok $o =~ /^New user with UUID '(\S+)' created\.$/,
                        'Correct output text format';
                    my $new_id = $1;
                    is scalar(keys %{$model->all_users}) =>
                        $user_count + 1,
                        'Entity count increased by one';
                    my $e = $model->get_user($new_id);
                    ok defined($e), 'Got a new user';
                    is_deeply $e->{data} => {a => 42}, 'Correct data';
                }, 'Plain hash syntax');

                $user_count = keys %{$model->all_users};
                $t->command_output(vg_user =>
                ['-c', $e1_id, "{b => 17, c => {answer => 42}}"] =>
                sub ($o) {
                    ok $o =~ /^New user with UUID '(\S+)' created\.$/,
                        'Correct output text format';
                    my $new_id = $1;
                    is scalar(keys %{$model->all_users}) =>
                        $user_count + 1,
                        'Entity count increased by one';
                    my $e = $model->get_user($new_id);
                    ok defined($e), 'Got a new user';
                    is_deeply $e->{data} =>
                        {b => 17, c => {answer => 42}},
                        'Correct data';
                }, 'Hash syntax with surrounding braces');
            };
        };
    };

    subtest Update => sub {
        ok 1; # TODO
    };

    subtest Delete => sub {
        ok 1; # TODO
    };

};

done_testing;
