package ViralGiral::Command::vg_entity;
use Mojo::Base 'Mojolicious::Command', -signatures;

has description => sub ($self) {
    $self
        ->with_roles('ViralGiral::Command')
        ->desc_with_thing('entity', 'entities');
};

has usage => sub ($self) {
    $self
        ->with_roles('ViralGiral::Command')
        ->usage_with_thing('entity', 'entities');
};

sub run ($self, @args) {
    $self
        ->with_roles('ViralGiral::Command')
        ->run_with_thing(entity => @args);
}

1;
__END__
