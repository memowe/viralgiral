package ViralGiral::Controller::Introspection;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub list_entities ($c) {
    my $es = $c->viralgiral_data->all_entities;
    my %uc = map {$_ => scalar @{$es->{$_}{users}}} keys %$es;
    $c->stash(entities => $es, user_count => \%uc);
}

sub show_entity ($c) {
    my $e = $c->viralgiral_data->get_entity($c->param('uuid'));
    return $c->reply->not_found unless defined $e;
    $c->stash(entity => $e);
}

sub show_user ($c) {
    my $u = $c->viralgiral_data->get_user($c->param('uuid'));
    return $c->reply->not_found unless defined $u;
    $c->stash(user => $u);
}

1;

__DATA__

@@ introspection/list_entities.html.ep
% layout 'vg_intro', title => 'Entity listing';
% use POSIX 'strftime';
% use Data::Dump 'pp';

<table class="table table-hover">

    <thead class="thead-light"><tr>
        <th scope="col">Entity UUID</th>
        <th scope="col">Created</th>
        <th scope="col">Data</th>
        <th scope="col">User count</th>
    </tr></thead>

    <tbody>
    % for my $uuid (sort {$entities->{$a}{created} <=> $entities->{$b}{created}} keys %$entities) {
    %   my $e = $entities->{$uuid};
        <tr>
            <th scope="row">
                %= link_to shorten($uuid) => vg_intro_show_entity => {uuid => $uuid}
            </th>
            <td><%= strftime '%F %T' => localtime $e->{created} %></td>
            <td><pre><code><%= pp $e->{data} %></code></pre></td>
            <td class="number"><%= $user_count->{$uuid} %></td>
        </tr>
    % }
    </tbody>
</table>

@@ introspection/show_entity.html.ep
% layout 'vg_intro', title => 'Entity ' . shorten $uuid;
% use POSIX 'strftime';
% use Data::Dump 'pp';

<ul id="entity-base-data" class="list-group">
    <li class="list-group-item"><strong>UUID</strong>:
        <code><%= $entity->{uuid} %></code></li>
    <li class="list-group-item"><strong>Created</strong>:
        <%= strftime '%F %T' => localtime $entity->{created} %></li>
</ul>

<h2>Entity data</h2>
<table id="entity-data" class="table table-hover">
    <thead class="thead-light">
        <th scope="col">Field</th>
        <th scope="col">Data</th>
    </thead>
    <tbody>
    % for my $field (sort keys %{$entity->{data}}) {
        <tr>
            <th scope="row"><%= $field %></th>
            <td><code><%= pp $entity->{data}{$field} %></code></td>
        </tr>
    % }
    </tbody>
</table>

<p><%= link_to 'All entities listing' => 'vg_intro_list_entities' %></p>

<h2>Users listing</h2>
% my @users = map {viralgiral_data->get_user($_)} @{$entity->{users}};
<table id="entity-users" class="table table-hover">
    <thead class="thead-light">
        <th scope="col">User UUID</th>
        <th scope="col">Created</th>
        <th scope="col">Data</th>
    </thead>
    <tbody>
    % for my $user (@users) {
        <tr>
            <th scope="row">
                %= link_to shorten($user->{uuid}) => vg_intro_show_user => {uuid => $user->{uuid}}
            </th>
            <td><%= strftime '%F %T' => localtime $user->{created} %></td>
            <td><pre><code><%= pp $user->{data} %></code></pre></td>
        </tr>
    % }
    </tbody>
</table>

<p><%= link_to 'All entities listing' => 'vg_intro_list_entities' %></p>

@@ introspection/show_user.html.ep
% layout 'vg_intro', title => 'User ' . shorten $uuid;
% use POSIX 'strftime';
% use Data::Dump 'pp';
<p><strong>TODO</strong></p>

@@ layouts/vg_intro.html.ep
<!doctype html>
<html><head>
    %= t title => $title
    %= t meta => (name => 'viewport', content => 'width=device-width, initial-scale=1, shrink-to-fit=no')

    %# JQuery (bundled with Mojolicious, no CDN neccessary)
    %= javascript '/mojo/jquery/jquery.js'
    %#= javascript 'https://code.jquery.com/jquery-3.3.1.slim.min.js'

    %# Bootstrap
    %= javascript 'https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.6/umd/popper.min.js'
    %= javascript 'https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/js/bootstrap.min.js'
    %= stylesheet 'https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/css/bootstrap.min.css'

    %# Custom CSS
    %= stylesheet '/introspection/style.css'

</head><body>

<header>
    %= t strong => 'ViralGiral Introspection'
    %= link_to 'All entities' => 'vg_intro_list_entities'
</header>

<main class="container">
    <div class="row"><div class="col"></div><div class="col-lg-10 col-12">
        <h1><%= $title %></h1>
        %= content
    </div><div class="col"></div></div>
</main>

</body></html>

@@ introspection/style.css

header {
    color           : white;
    background-color: black;
    font-size       : 1.1em;
    padding         : .8em 3ex;
    box-shadow      : 0 3px 4px lightgrey;
}

header strong {
    border-right    : thin solid darkgrey;
    padding-right   : 3ex;
    margin-right    : 2ex;
    font-size       : 1.1em;
}

header a {
    color           : lightgrey;
}

header a:hover, header a:active {
    color           : white;
    text-decoration : none;
}

h1 {
    margin          : 2em 0 1em;
}

h2 {
    margin          : 1em 0 .5em;
}

table td.number {
    text-align      : right;
}
