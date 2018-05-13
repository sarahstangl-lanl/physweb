package UMPhysics::FormHandler::AuthTrait;

use HTML::FormHandler::Moose::Role;

# Edit authorization
has 'auth' => ( isa => 'Bool|CodeRef|ArrayRef', is => 'rw', default => 1 );

# Read authorization
# Defaults to $self->build_read_auth method if exists, otherwise edit auth above
has 'read_auth' => (
    isa => 'Bool|CodeRef|ArrayRef',
    is => 'rw',
    lazy => 1,
    builder => '_build_read_auth'
);

sub _build_read_auth {
    my $self = shift;
    if (my $method = $self->can('build_read_auth')) {
        return $self->$method;
    }
    return shift->auth;
}

# Allow auth params to override foreman auth - set to 1 to prevent foreman auth_arg from overriding auth params
has 'auth_over_foreman' => ( isa => 'Bool', is => 'rw', default => 0 );

# Place to store calculated field edit/read auth
has [ '_edit_auth', '_read_auth' ] => ( isa => 'Bool', is => 'rw' );

# Global field methods
# Methods return values from $auth_args hash, e.g. $self->_uid() returns $auth_args{'uid'}
# Access with $form->field('field_name')->method or $self->method from within field subs
sub _uid {
    my $self = shift;
    return $self->form->_uid();
}

sub _customer_id {
    my $self = shift;
    return $self->form->_customer_id();
}

sub _machinist_id {
    my $self = shift;
    return $self->form->_machinist_id();
}

# Returns 1 if user has edit authorization for this field, 0 otherwise
sub has_auth {
    my ($self) = @_;

    my $auth = $self->form->auth_args || {};
    if (ref($self->auth) eq 'CODE') {
        return $self->auth->($auth, $self->form->item);
    }
    elsif (ref($self->auth) eq 'ARRAY') {
        return $self->check_auth($auth, $self->form->item, $self->auth, 'edit');
    }
    return $self->auth;
}

# Returns 1 if user has read authorization for this field, 0 otherwise
sub has_read_auth {
    my ($self) = @_;

    my $auth = $self->form->auth_args || {};
    if (ref($self->read_auth) eq 'CODE') {
        return $self->read_auth->($auth, $self->form->item);
    }
    elsif (ref($self->read_auth) eq 'ARRAY') {
        return $self->check_auth($auth, $self->form->item, $self->read_auth, 'read');
    }
    return $self->read_auth;
}

# Determines auth based on $self->auth/$self->read_auth arrays
# Array syntax tries to mirror syntax of SQL::Abstract WHERE args
# $self->auth is treated as an array of ORs
# Each array element as treated as a hash of ANDs
# Each hash value is treated as an array of ORs
# Example:
# [ { item => [ 'new' ] }, { item => [ '!finalized' ], auth_args => [ 'customer', 'machinists' ] } ]
# This is equivalent to
#      item = 'new'
#   OR (
#           item != 'finalized'
#       AND (
#               auth_args = 'customer'
#            OR auth_args = 'machinists'
#           )
#      )
# Any value can be preceded by an exclamation point to negate the result
# Results for item values are determined by the return value of $item->$value,
# so any valid item method can be used as a value
# item = 'new' does not check $item->new, but rather is equal to defined($form->item)
# New item methods can be added by creating additional subs in ShopDb::Schema::Result files
# Results for auth_args values are determined by the value of $form->auth_args->{$value}
# See UMPhysics/FormHandler/Auth.pm for information on populating $form->auth_args
sub check_auth {
    my ($self, $auth_args, $item, $auth_clauses, $auth_type) = @_;
#    warn "check_auth $auth_type for field " . $self->name();
    return 1 if $auth_args->{'foreman'} && !$self->auth_over_foreman;
    my $store_method = "_${auth_type}_auth";
    return $self->$store_method if ($self->form->_auth_processed);
    my $auth = 0;
    sub check {
        my ($arg, $value) = @_;
        return ($arg =~ /^\!/ ? !$value : !(!$value));
    }
    foreach my $or_clause (@$auth_clauses) { # OR
        $auth = 1;
        foreach my $auth_type (keys %$or_clause) { # AND
#            warn "Checking auth_type $auth_type:\n" . Data::Dumper::Dumper($or_clause);
            if ($auth_type eq 'item') {
                my $auth_state = 0;
                foreach my $item_state (@{$or_clause->{'item'}}) { # OR
                    (my $filtered_state = $item_state) =~ s/^\!//;
                    if ($filtered_state eq 'new') {
                        if (check($item_state, !$item)) {
                            $auth_state = 1;
                            last;
                        }
                        next;
                    }
                    unless ($item) {
                        next;
                    }
                    my $method;
                    die "Invalid method '$filtered_state'" unless $method = $item->can($filtered_state);
                    if (check($item_state, $item->$method)) {
                        $auth_state = 1;
                        last;
                    }
                }
                if (!$auth_state) {
                    $auth = 0;
                    last;
                }
            }
            elsif ($auth_type eq 'auth_args') {
                my $args_auth = 0;
                foreach my $auth_arg (@{$or_clause->{'auth_args'}}) {
                    (my $filtered_arg = $auth_arg) =~ s/^\!//;
                    if (check($auth_arg, $auth_args->{$filtered_arg})) {
                        $args_auth = 1;
                        last;
                    }
                }
                if (!$args_auth) {
                    $auth = 0;
                    last;
                }
            }
            else {
                die "Invalid auth type $auth_type";
            }

        }
        last if $auth;
    }
#    warn "setting auth to $auth";
    $self->$store_method($auth);
    return $auth;
}

no HTML::FormHandler::Moose::Role;
1;
