package ViralGiral::Command::vg_user;
use Mojo::Base 'Mojolicious::Command', -signatures;

has description => sub ($self) {
    $self
        ->with_roles('ViralGiral::Command')
        ->desc_with_thing('user', 'users');
};

has usage => sub ($self) {
    $self
        ->with_roles('ViralGiral::Command')
        ->usage_with_thing('user', 'users');
};

sub run ($self, @args) {
    $self
        ->with_roles('ViralGiral::Command')
        ->run_with_thing(user => @args);
}

1;
__END__
