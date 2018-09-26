package ViralGiral::Data;
use Mojo::Base -base, -signatures;

use ViralGiral::Data::EventStore;

use File::stat;
use UUID::Tiny 'create_uuid_as_string';

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

sub add_entity ($self, $data = {}) {

    # Prepare
    my $uuid = create_uuid_as_string;

    # Store event
    $self->events->store_event(EntityAdded => {uuid => $uuid, data => $data});

    # Return generated entity identifier
    return $uuid;
}

sub all_entities ($self) {
    return $self->_get('entity');
}

sub get_entity ($self, $uuid) {
    return $self->_get('entity')->{$uuid};
}

sub modify_entity ($self, $uuid, $data) {

    # Entity lookup
    my $e = $self->_get('entity')->{$uuid};
    die "Unknown entity with UUID '$uuid'\n" unless defined $e;

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
    die "Unknown entity with UUID '$uuid'\n"
        unless defined $self->_get('entity')->{$uuid};

    # Store event
    $self->events->store_event(EntityDeleted => {uuid => $uuid});
}

sub add_user ($self, $entity_uuid, $reference, $data = {}) {

    # Entity lookup
    die "Unknown entity with UUID '$entity_uuid'\n"
        unless defined $self->_get('entity')->{$entity_uuid};

    # Reference lookup
    die "Unknown user reference with UUID '$reference'\n"
        if defined $reference and not defined $self->_get('user')->{$reference};

    # Prepare
    my $uuid = create_uuid_as_string;

    # Store event
    $self->events->store_event(UserAdded => {
        uuid        => $uuid,
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

    # User lookup
    my $u = $self->_get('user')->{$uuid};
    die "Unknown user with UUID '$uuid'\n" unless defined $u;

    return $u;
}

sub modify_user ($self, $uuid, $data) {

    # User lookup
    my $u = $self->_get('user')->{$uuid};
    die "Unknown user with UUID '$uuid'\n" unless defined $u;

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
    die "Unknown user with UUID '$uuid'\n"
        unless defined $self->_get('user')->{$uuid};

    # Store event
    $self->events->store_event(UserDeleted => {uuid => $uuid});
}

1;
__END__
