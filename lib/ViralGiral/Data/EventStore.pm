package ViralGiral::Data::EventStore;
use Mojo::Base -base, -signatures;

use EventStore::Tiny;
use Time::HiRes 'time';
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
##          data: \%user_data,
##      }
##  }

has data_filename   => ();
has _est            => sub ($self) {
    my $est_fn = $self->data_filename;

    # Create event store
    my $store = (defined $est_fn and -e $est_fn)
        ? EventStore::Tiny->new_from_file($est_fn)
        : EventStore::Tiny->new;
    $store->init_data({entity => {}, user => {}});
    $store->cache_distance(0);
    $store->slack(1); # we know what we're doing

    return $store;
};

sub store_to_file ($self) {
    die "No data_filename given!\n"
        unless defined $self->data_filename;
    $self->_est->store_to_file($self->data_filename);
}

# Helper
sub store_event ($self, @args) {$self->_est->store_event(@args)}
sub logger ($self, @args) {$self->_est->logger(@args)}

sub init ($self) {

    # An entity has been added
    $self->_est->register_event(EntityAdded => sub ($state, $data) {
        $state->{entity}{$data->{uuid}} = {
            uuid    => $data->{uuid},
            created => time,
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
            created     => time,
            entity      => $data->{entity_uuid},
            reference   => $data->{reference}, # possibly undef
            data        => clone($data->{data}),
        };
        push @{$state->{entity}{$data->{entity_uuid}}{users}}, $data->{uuid};
    });

    # A user has been modified
    $self->_est->register_event(UserModified => sub ($state, $data) {
        $state->{user}{$data->{uuid}}{data}{$_} = $data->{data}{$_}
            for keys %{$data->{data}};
    });

    # A user has been deleted
    $self->_est->register_event(UserDeleted => sub ($state, $data) {
        my $e = $state->{entity}{$state->{user}{$data->{uuid}}->{entity}};
        @{$e->{users}} = grep {$_ ne $data->{uuid}} @{$e->{users}};
        delete $state->{user}{$data->{uuid}};
    });
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
