package ViralGiral;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use ViralGiral::Data;
use ViralGiral::Controller::Actions;

our $VERSION = '0.01';

sub register ($self, $app, $conf) {

    # Default values
    my $data_fn = $conf->{data_filename} // $app->home->rel_file('VG_data');
    my $prefix  = $conf->{prefix}        // 'vg';

    # Add viralgiral data helper
    $app->helper(viralgiral_data => sub {
        state $vgd = ViralGiral::Data->new(data_filename => $data_fn);
    });

    # Add shortener helper
    $app->helper(shorten => sub ($c, $text, $length = 8) {
        return $text if $length >= length $text;
        $text =~ s/^(.{$length}).*/$1.../;
        return $text;
    });

    # Inject routes
    my $r = $app->routes->detour(namespace => 'ViralGiral::Controller');
    $r->get("$prefix/info")->to('actions#info')->name('vg_info');

    # Inject inline templates and static assets
    push @{$app->renderer->classes},
        'ViralGiral::Controller::Actions';
}

1;
__END__
