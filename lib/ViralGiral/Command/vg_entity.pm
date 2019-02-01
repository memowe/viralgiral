package ViralGiral::Command::vg_entity;
use Mojo::Base 'Mojolicious::Command', -signatures;

use ViralGiral::Command qw(
    desc_with_thing
    usage_with_thing
    run_with_thing
);

has description => sub ($self) {$self->desc_with_thing('entity', 'entities')};
has usage       => sub ($self) {$self->usage_with_thing('entity', 'entities')};

sub run ($self, @args) {
    return $self->run_with_thing(entity => @args);
}

1;
__END__
