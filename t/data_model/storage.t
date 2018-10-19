#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp;
use File::stat;

use_ok 'ViralGiral::Data';

subtest 'No filename given' => sub {
    my $model = ViralGiral::Data->new;
    throws_ok {$model->store} qr/No data_filename given!/,
        'Correct error message';
};

# Create a temporary file
my $tmpf    = File::Temp->new;
my $fn      = $tmpf->filename;

# Prepare
my $model = ViralGiral::Data->new;
$model->logger(undef);
my $e_id = $model->add_entity({foo => 42});
$model->events->data_filename($fn);

subtest 'Initial emptiness' => sub {
    is $model->last_storage => 0, 'Last storage timestamp is 0';
    is stat($tmpf)->size => 0, 'File still empty';
};

# Store
$model->store;

subtest 'Stored correctly' => sub {
    ok 1 >= time - $model->last_storage, 'There was an update';
    ok stat($tmpf)->size != 0, 'File not empty';
    ok 1 > time - stat($tmpf)->mtime, 'File modified recently';

    # Read from it
    my $m2 = ViralGiral::Data->new(data_filename => $fn);
    is $m2->get_entity($e_id)->{data}{foo} => 42, 'Correct data';
};

subtest 'Storage neccessary?' => sub {

    subtest 'No' => sub {
        sleep 1; # Wait to see a difference in timestamps
        ok ! $model->store_if_neccessary, 'Storage not neccessary';
        ok 1 <= time - stat($tmpf)->mtime, 'File not modified';
    };

    subtest 'Yes' => sub {
        sleep 1; # Wait to see a difference in timestamps
        $model->modify_entity($e_id, {foo => 17});
        ok $model->store_if_neccessary, 'Storage neccessary';
        ok 1 > time - stat($tmpf)->mtime, 'File modified';

        # Check content
        my $m2 = ViralGiral::Data->new(data_filename => $fn);
        is $m2->get_entity($e_id)->{data}{foo} => 17, 'Correct data';
    };
};

done_testing;
