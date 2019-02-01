package ViralGiral::Command;
use Mojo::Base -strict, -signatures;
use Exporter 'import';

our @EXPORT_OK = qw(
    desc_with_thing
    usage_with_thing
    run_with_thing
);

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
    print $self->usage and return if $args[0] eq 'help';
    print "TODO: Do something with $thing and @args";
}

1;
__END__
