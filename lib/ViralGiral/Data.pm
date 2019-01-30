package ViralGiral::Data;
use Mojo::Base -base, -signatures;
use Carp;

use ViralGiral::Data::EventStore;

use File::stat;
use UUID::Tiny 'create_uuid_as_string';
use Time::HiRes 'time';

has data_filename   => ();
has last_storage    => sub ($self) {

    # Is there already something? Use its last modified time
    my $dfn = $self->data_filename;
    return stat($dfn)->mtime if defined $dfn and -e $dfn;

    # Nothing to read from
    return 0;
};
has events => sub ($self) {
    my $events = ViralGiral::Data::EventStore->new(
        data_filename => $self->data_filename,
    );
    $events->init;
    return $events;
};

sub logger ($self, $logger = undef) {
    $self->events->logger($logger);
}

sub store ($self) {
    $self->events->store_to_file;
    $self->last_storage($self->events->last_update);
}

# Returns true iff it was neccessary
sub store_if_neccessary ($self) {

    # Updated since last storage: neccessary
    if ($self->last_update > $self->last_storage) {
        $self->store;
        return 1;
    }

    # Not neccessary
    return;
}

sub is_empty ($self) {
    return $self->events->is_empty;
}

sub last_update ($self) {
    return $self->events->last_update;
}

sub _get ($self, $key) {
    return $self->events->state->{$key};
}

## CRUD methods ##

sub add_entity ($self, $data = {}) {

    # Prepare
    my $uuid = create_uuid_as_string;

    # Store event and inject timestamp
    $self->events->store_event(EntityAdded => {
        uuid    => $uuid,
        created => time,
        data    => $data,
    });

    # Return generated entity identifier
    return $uuid;
}

sub all_entities ($self) {
    return $self->_get('entity');
}

sub get_entity ($self, $uuid) {
    return unless defined $uuid;
    return $self->_get('entity')->{$uuid};
}

sub modify_entity ($self, $uuid, $data) {

    # Entity lookup
    my $e = $self->get_entity($uuid);
    my $uuid_str = $uuid // 'undef';
    croak "Unknown entity with UUID '$uuid_str'\n" unless defined $e;

    # Mix data updates in
    my %new_data = (%{$e->{data}}, %$data);

    # Store event
    $self->events->store_event(EntityModified => {
        uuid => $uuid,
        data => \%new_data
    });
}

sub delete_entity ($self, $uuid) {

    # Entity lookup
    my $uuid_str = $uuid // 'undef';
    croak "Unknown entity with UUID '$uuid_str'\n"
        unless defined $self->get_entity($uuid);

    # Store event
    $self->events->store_event(EntityDeleted => {uuid => $uuid});
}

sub add_user ($self, $entity_uuid, $reference, $data = {}) {

    # Entity lookup
    my $e = $self->get_entity($entity_uuid);
    my $entity_uuid_str = $entity_uuid // 'undef';
    croak "Unknown entity with UUID '$entity_uuid_str'\n" unless defined $e;

    # Reference lookup
    croak "Unknown user reference with UUID '$reference'\n"
        if defined $reference and not defined $self->get_user($reference);

    # Prepare
    my $uuid = create_uuid_as_string;

    # Store event
    $self->events->store_event(UserAdded => {
        uuid        => $uuid,
        created     => time,
        entity_uuid => $entity_uuid,
        reference   => $reference,
        data        => $data,
    });

    # Return generated user identifier
    return $uuid;
}

sub all_users ($self) {
    return $self->_get('user');
}

sub get_user ($self, $uuid) {
    return unless defined $uuid;
    return ($self->all_users // {})->{$uuid};
}

sub modify_user ($self, $uuid, $data) {

    # User lookup
    my $u = $self->get_user($uuid);
    my $uuid_str = $uuid // 'undef';
    croak "Unknown user with UUID '$uuid_str'\n" unless defined $u;

    # Mix data updates in
    my %new_data = (%{$u->{data}}, %$data);

    # Store event
    $self->events->store_event(UserModified => {
        uuid => $uuid,
        data => \%new_data
    });
}

sub delete_user ($self, $uuid) {

    # User lookup
    my $uuid_str = $uuid // 'undef';
    croak "Unknown user with UUID '$uuid_str'\n"
        unless defined $self->get_user($uuid);

    # Store event
    $self->events->store_event(UserDeleted => {uuid => $uuid});
}

## Data extraction methods ##

sub _get_user_strict ($self, $uuid) {
    my $u = $self->get_user($uuid);
    my $uuid_str = $uuid // 'undef';
    croak "Unknown user with UUID '$uuid_str'\n" unless defined $u;
    return $u;
}

sub get_entity_for_user ($self, $uuid) {
    return $self->get_entity($self->_get_user_strict($uuid)->{entity});
}

sub get_predecessor ($self, $uuid) {
    return $self->get_user($self->_get_user_strict($uuid)->{reference});
}

sub get_all_predecessors ($self, $uuid) {
    my $u = $self->_get_user_strict($uuid);

    # Keep track of intermediate predecessors
    my $puuid_todo = $u->{reference};

    # Iterate to the top
    my @predecessors;
    while (defined(my $p = $self->get_user($puuid_todo))) {
        $puuid_todo = $p->{reference};
        push @predecessors, $p;
    }

    # Done
    return \@predecessors;
}

sub get_successors ($self, $uuid) {
    my $user    = $self->_get_user_strict($uuid);
    return [map {$self->get_user($_)} @{$user->{successors}}];
}

sub get_all_successors ($self, $uuid) {
    my $user = $self->_get_user_strict($uuid);

    # Keep track of all intermediate successors
    my @succ_uuids_todo = @{$user->{successors}};

    # Iterate
    my @successors;
    while (defined(my $user = $self->get_user(pop @succ_uuids_todo))) {
        push @successors, $user;
        push @succ_uuids_todo, @{$user->{successors}};
    }

    # Return sorted flat list of all successors
    return [sort {$a->{created} <=> $b->{created}} @successors];
}

1;
__END__
