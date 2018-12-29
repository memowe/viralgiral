package ViralGiral::Controller::Actions;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub info ($c) {
    $c->render(template => 'info');
}

1;

__DATA__

@@ layouts/viralgiral.html.ep
<!doctype html>
<html><head><title>ViralGiral <%= $action %></title></head><body>
    <p><strong>Warning</strong>:
        You should replace this template by defining your own
        <code><%= $action %>.html.ep</code> template.
    </p>
    %= content
</body></html>

@@ info.html.ep
% layout 'viralgiral';
<h1>ViralGiral is running!</h1>
<table border="1" cellpadding="3">
    <thead><tr><th></th><th>Version</th></tr></thead>
    <tbody>
        <tr><th>perl</th><td><%= $^V %></td></tr>
        <tr><th>ViralGiral</th><td><%= $ViralGiral::VERSION %></td></tr>
        <tr><th>Mojolicious</th><td><%= $Mojolicious::VERSION %></td></tr>
        <tr><th>EventStore::Tiny</th><td><%= $EventStore::Tiny::VERSION %></td></tr>
    </tbody>
</table>
