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

    ./app vg_$thing --list --sort=name
    ./app vg_$thing --add "name => 'Foo', color => 'white'"
    ./app vg_$thing --update "answer => 42" UUID
    ./app vg_$thing --delete UUID
USAGE
}

sub run_with_thing ($self, $thing, @args) {
    print $self->usage and return if $args[0] eq 'help';
    print "TODO: Do something with $thing and @args";
}

1;
__END__
