package ViralGiral;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use ViralGiral::Data;
use ViralGiral::Controller;

our $VERSION = '0.01';

sub register ($self, $app, $conf) {

    # Default values
    my $data_fn = $conf->{data_filename} // $app->home->rel_file('VG_data');
    my $prefix  = $conf->{prefix}        // 'vg';

    # Add viralgiral data helper
    $app->helper(viralgiral_data => sub {
        state $vgd = ViralGiral::Data->new(data_filename => $data_fn);
    });

    # Inject routes: dispatch to actions as methods in VG::Controller
    $app->routes->get("$prefix/:action")
        ->to('ViralGiral::Controller')->name('viralgiral');

    # Inject inline templates
    push @{$app->renderer->classes}, 'ViralGiral::Controller';
}

1;
__END__
