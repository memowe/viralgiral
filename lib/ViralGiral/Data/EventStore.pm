package ViralGiral::Data::EventStore;
use Mojo::Base -base, -signatures;
use Carp;

use EventStore::Tiny;
use Clone 'clone';

##
## DATA STORAGE LAYOUT
##
##  # Entities structure
##  entity: {
##      $E_UUID (representing an entity): {
##          uuid: $E_UUID,
##          created: $E_TS,
##          users: [ $U_UUID ],
##          data: \%entity_data,
##      }
##  }
##
##  # Index structure with an implicit reference tree structure
##  user: {
##      $U_UUID (representing a user): {
##          uuid: $U_UUID,
##          created: $U_TS,
##          entity: $E_UUID,
##          reference: $U2_UUID (or undef),
##          successors: [ $S_UUID ],
##          data: \%user_data,
##      }
##  }

has data_filename   => ();
has _est            => sub ($self) {
    my $store = EventStore::Tiny->new(logger => undef);
    $store->cache_distance(0);
    $store->slack(1); # we know what we're doing
    return $store;
};

sub store_to_file ($self) {
    croak "No data_filename given!\n"
        unless defined $self->data_filename;
    $self->_est->export_events($self->data_filename);
}

# Helper
sub store_event ($self, @args) {$self->_est->store_event(@args)}
sub logger ($self, @args) {$self->_est->logger(@args)}

sub init ($self) {

    # An entity has been added
    $self->_est->register_event(EntityAdded => sub ($state, $data) {
        $state->{entity}{$data->{uuid}} = {
            uuid    => $data->{uuid},
            created => $data->{created},
            users   => [],
            data    => clone($data->{data}),
        };
    });

    # An entity has been modified
    $self->_est->register_event(EntityModified => sub ($state, $data) {
        $state->{entity}{$data->{uuid}}{data}{$_} = $data->{data}{$_}
            for keys %{$data->{data}};
    });

    # An entity has been deleted
    $self->_est->register_event(EntityDeleted => sub ($state, $data) {
        delete $state->{user}{$_}
            for @{$state->{entity}{$data->{uuid}}{users}};
        delete $state->{entity}{$data->{uuid}};
    });

    # A user has been added
    $self->_est->register_event(UserAdded => sub ($state, $data) {
        $state->{user}{$data->{uuid}} = {
            uuid        => $data->{uuid},
            created     => $data->{created},
            entity      => $data->{entity_uuid},
            reference   => $data->{reference}, # possibly undef
            successors  => [],
            data        => clone($data->{data}),
        };

        # Add to parent successors
        push @{$state->{user}{$data->{reference}}{successors}}, $data->{uuid}
            if defined $data->{reference};

        # Add to entity users
        push @{$state->{entity}{$data->{entity_uuid}}{users}}, $data->{uuid};
    });

    # A user has been modified
    $self->_est->register_event(UserModified => sub ($state, $data) {
        $state->{user}{$data->{uuid}}{data}{$_} = $data->{data}{$_}
            for keys %{$data->{data}};
    });

    # A user has been deleted
    $self->_est->register_event(UserDeleted => sub ($state, $data) {

        # Shortcuts
        my $uuid = $data->{uuid};
        my $u = $state->{user}{$uuid};
        my $e = $state->{entity}{$u->{entity}};

        # Delete from entity users
        @{$e->{users}} = grep {$_ ne $uuid} @{$e->{users}};

        # Delete from parent user successors
        if (defined $u->{reference}) {
            my $r = $state->{user}{$u->{reference}};
            @{$r->{successors}} = grep {$_ ne $uuid} @{$r->{successors}};
        }

        # Delete as parent reference from successors
        $state->{user}{$_}{reference} = undef for @{$u->{successors}};

        # Delete
        delete $state->{user}{$uuid};
    });

    # Import existing events, if any
    my $est_fn = $self->data_filename;
    $self->_est->import_events($est_fn) if defined $est_fn and -e $est_fn;
}

sub is_empty ($self) {
    return $self->_est->events->size == 0;
}

sub last_update ($self) {
    return $self->_est->events->last_timestamp // 0;
}

sub state ($self, $time = undef) {
    return $self->_est->snapshot($time)->state;
}

1;
__END__
