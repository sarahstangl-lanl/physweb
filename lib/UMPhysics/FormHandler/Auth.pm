package UMPhysics::FormHandler::Auth;

use HTML::FormHandler::Moose::Role;

# Using 'before' significantly impacts performance, so _auth_process is no longer called automatically
# This impact can be avoided by calling $self->_auth_process manually from any other form method
# So, be sure to call $form->_auth_process manually before checking auth
#before 'process' => \&_auth_process;
#before 'is_valid' => \&_auth_process;

# Overall form auth
has 'auth' => ( isa => 'Bool|CodeRef', is => 'rw', default => 1 );

# Hash of field_name => field_method pairs used in determining field auth
# $self->auth_args->{field_name} is set to result of ($field->value eq $field->field_method)
has 'auth_field_list' => ( isa => 'HashRef', is => 'rw', default => sub { {} } );

# Hash of values used in determining auth
# This value is stored globally in $session{'shopdb-auth'} and must be passed in on $form->new()
# Some values are added automatically by the autohandler including uid, customer_id, machinist_id and foreman
# The value of foreman is determined by membership in the shopdb-foreman web group
# customer_id and machinist_id are retrieved based on $session{'uid'}
# New auth_args values can be added by defining $form->auth_field_list as described above
has 'auth_args' => ( isa => 'HashRef', is => 'rw', required => 1 );

# Bool to prevent useless reprocessing of auth
# Set to 0 with $form->_auth_processed(0) to cause auth to be recalculated
has '_auth_processed' => ( isa => 'Bool', is => 'rw' );

# Array of fields with edit auth. Populated by _auth_process.
# $form->num_auth_edit_fields returns count of fields with edit auth
has 'auth_edit_fields' => (
    isa => 'ArrayRef',
    is => 'rw',
    traits => ['Array'],
    default => sub {[]},
    handles => {
        add_auth_edit_field => 'push',
        num_auth_edit_fields => 'count',
        clear_auth_edit_fields => 'clear',
        has_auth_edit_fields => 'count',
    },
);

# Array of fields with read auth. Populated by _auth_process.
# $form->num_auth_read_fields returns count of fields with read auth
has 'auth_read_fields' => (
    isa => 'ArrayRef',
    is => 'rw',
    traits => ['Array'],
    default => sub {[]},
    handles => {
        add_auth_read_field => 'push',
        num_auth_read_fields => 'count',
        clear_auth_read_fields => 'clear',
        has_auth_read_fields => 'count',
    },
);

# Global form methods (can be accessed anywhere as $form->method)
sub _uid {
    my $self = shift;
    return $self->auth_args->{uid};
}

sub _customer_id {
    my $self = shift;
    return $self->auth_args->{customer_id};
}

sub _machinist_id {
    my $self = shift;
    return $self->auth_args->{machinist_id};
}

# Overall form auth check sub
sub has_auth {
    my ($self) = @_;
    my $auth = $self->auth_args;
#    warn "Auth::has_auth for form " . $self . " / ref(\$self->auth): " . ref($self->auth);
    if (ref($self->auth) eq 'CODE') {
        return $self->auth->($auth, $self);
    }
    else {
        return $self->auth;
    }
}

# Sub to process auth_field_list
sub _build_auth_args {
    my $self = shift;
#    warn '_build_auth_args';
    my $auth_args = $self->auth_args;
    my $auth_field_list = $self->auth_field_list;
    while (my ($field, $compare_method_name) = each %{$auth_field_list}) {
        die "Could not find field $field but listed in auth_field_list" unless $self->field($field);
        die "Field $field does not support method $compare_method_name but listed in auth_field_list" unless my $method = $self->can($compare_method_name);
        my $value = $self->field($field)->value;
        my $compare_value = $self->$method;
        # Prevent empty value arrays from leaving previous value set
        unless ((defined($value) && !ref($value)) || (ref($value) eq 'ARRAY' && scalar(@$value))) {
            $auth_args->{$field} = 0;
            next;
        }
        if (ref($value) eq 'ARRAY') {
            foreach (@$value) {
                if (defined($compare_value) && $_ eq $compare_value) {
                    $auth_args->{$field} = 1;
                    last;
                }
                else {
                    $auth_args->{$field} = 0;
                }
            }
        }
        else {
            if (defined($compare_value) && $value eq $compare_value) {
                $auth_args->{$field} = 1;
            }
            else {
                $auth_args->{$field} = 0;
            }
        }
    }
    $self->auth_args($auth_args);
}

# Set field read-only/rw status and disable/enable database updates based on auth params
sub _auth_process {
    my $self = shift;
#    warn '_auth_process';

    return if ($self->_auth_processed);

    $self->_build_auth_args;

    my $form_auth = $self->has_auth;
    $self->clear_auth_edit_fields;
    $self->clear_auth_read_fields;

    my @fields = $self->fields;
    foreach my $field (@fields) {
        if ($form_auth && $field->has_auth) {
            $self->add_auth_edit_field($field);
            $field->noupdate(0);
            if ($field->type =~ m/^(Select|Multiple|Checkbox)$/) {
                $field->disabled(0);
            }
            else {
                $field->readonly(0);
            }
        } else {
            $field->noupdate(1);
            if ($field->type =~ m/^(Select|Multiple|Checkbox)$/) {
                $field->disabled(1);
            }
            else {
                $field->readonly(1);
            }
        }
        if ($form_auth && $field->has_read_auth) {
            $self->add_auth_read_field($field);
        }
    }

    $self->_auth_processed(1);

};

no HTML::FormHandler::Moose::Role;
1;
