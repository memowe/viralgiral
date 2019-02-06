package ViralGiral::Command;
use Role::Tiny;
use Mojo::Base -strict, -signatures;
use Mojo::Util 'getopt';
use POSIX 'strftime';
use Data::Dump 'dump';

sub desc_with_thing ($self, $thing, $things) {
    "Show or manipulate $things"
}

sub usage_with_thing ($self, $thing, $things) {
    <<"USAGE"
Usage: APPLICATION vg_$thing [OPTIONS] [UUID]

    ./app vg_$thing UUID
    ./app vg_$thing --list --sort=name
    ./app vg_$thing --create "name => 'Foo', color => 'white'"
    ./app vg_$thing --update "answer => 42" UUID
    ./app vg_$thing --delete UUID

Runmode list (--list [--sort X] [--show Y] [UUID])

    - List all $things sorted by creation time.
    - List all $things sorted by data field "foo" with --sort foo.
    - Explicitly add data field "bar" to listing with --show bar.
    - Complete dump of all data of the $thing when a UUID is given.
    - The list runmode is default, so it doesn't need to be typed.

Runmode create (--create DATA_STRING)

    - Create a new $thing, the created UUID is printed back.
    - Interprete the given DATA_STRING as the new data hash.
    - Print the UUID of the created $thing.

Runmode update (--update DATA_STRING UUID)

    - Update the $thing with the given UUID.
    - Use the DATA_STRING to update single data hash values.

Runmode delete (--delete UUID)

    - Delete the $thing with the given UUID. (Caution!)
USAGE
}

sub run_with_thing ($self, $thing, @args) {

    # Collect options
    my @old_args = @args;
    getopt \@args, (

        # Run modes
        'l|list'    => \my $rm_list,
        'c|create'  => \my $rm_create,
        'u|update'  => \my $rm_update,
        'd|delete'  => \my $rm_delete,

        # Run mode list modifiers
        'sort=s'    => \my $sort,
        'show=s'    => \my $show,
    );

    $DB::single = 1;

    # Disambiguation: more than one runmode activated
    return print "Ambiguous options '@old_args'!\n\n" . $self->usage
        if 1 < grep defined($_) =>
        $rm_list, $rm_create, $rm_update, $rm_delete;

    # Dispatch run modes
    return $self->_list($thing, $sort, $show, @args)    if $rm_list;
    return $self->_create($thing, @args)                if $rm_create;
    return $self->_update($thing, @args)                if $rm_update;
    return $self->_delete($thing, @args)                if $rm_delete;

    # Anything else, incl. 'help'
    return print $self->usage;
}

sub _list ($self, $thing, $sort, $show, @args) {
    my $uuid = shift @args;
    return $self->_list_thing($thing, $uuid) if defined $uuid;
    return $self->_list_all($thing, $sort, $show);
}

sub _list_thing ($self, $thing, $uuid) {

    # Collect thing data
    my $getter = $thing eq 'entity' ? 'get_entity' : 'get_user';
    my $thing_data = $self->app->viralgiral_data->$getter($uuid);

    # Prepare output
    my $output = $self->_summarize($thing, 1, $thing_data)
        . 'Data: ' . dump($thing_data->{data}) . "\n";

    # Entity: add user summaries
    if ($thing eq 'entity') {
        my @user_datas = map
            {$self->app->viralgiral_data->get_user($_)}
            @{$thing_data->{users}};
        $output .= "Users:\n";
        $output .= $self->_summarize('user', undef, $_) for @user_datas;
    }

    # Done
    return print $output;
}

sub _list_all ($self, $thing, $sort, $show) {
    my $getter = $thing eq 'entity' ? 'all_entities' : 'all_users';
    my %thing_data = %{$self->app->viralgiral_data->$getter};

    # Prepare things
    my @thing_uuids = sort
        {$thing_data{$b}{created} <=> $thing_data{$a}{created}}
        keys %thing_data;

    # Sort again, if neccessary
    @thing_uuids = sort
        {$thing_data{$a}{data}{$sort} cmp $thing_data{$b}{data}{$sort}}
        @thing_uuids
        if defined $sort;

    # Build output
    return print join '' => map
        {$self->_summarize($thing, 1, $thing_data{$_}, $show)}
        @thing_uuids;
}

sub _summarize ($self, $thing, $verbose, $thing_data, $show = undef) {

    # First part
    my $output = ucfirst $thing
        . ' ' . $thing_data->{uuid}
        . ' | ' . strftime('%F %T' => localtime $thing_data->{created});

    # Entity? Add users
    if ($thing eq 'entity') {
        $output .= ', ' . @{$thing_data->{users}} . ' user(s)';
    }

    # Users and not short? Add entity and maybe parent
    if ($thing eq 'user' and $verbose) {
        $output .= ", entity $thing_data->{entity}";
        $output .= ", parent $thing_data->{reference}"
            if defined $thing_data->{reference};
    }

    # Show something special?
    $output .= " | $show: " . dump $thing_data->{data}{$show}
        if defined $show;

    # Done
    return "$output\n";
}

sub _create ($self, $thing, @args) {
}

sub _update ($self, $thing, @args) {
}

sub _delete ($self, $thing, @args) {
}

1;
__END__
