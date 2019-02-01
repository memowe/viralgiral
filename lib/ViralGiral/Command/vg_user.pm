package ViralGiral::Command::vg_user;
use Mojo::Base 'Mojolicious::Command', -signatures;

use ViralGiral::Command qw(
    desc_with_thing
    usage_with_thing
    run_with_thing
);

has description => sub ($self) {$self->desc_with_thing('user', 'users')};
has usage       => sub ($self) {$self->usage_with_thing('user', 'users')};

sub run ($self, @args) {
    return $self->run_with_thing(user => @args);
}

1;
__END__
