package ShopDb::Form::Base;

use HTML::FormHandler::Moose;
use POSIX qw(strftime);

extends 'HTML::FormHandler::Model::DBIC';
with 'UMPhysics::FormHandler::Auth';

has '+widget_name_space' => ( default => sub { ['ShopDb::Widget', 'UMPhysics::Widget'] } );
has '+widget_form' => ( default => 'Table' );
has '+widget_wrapper' => ( default => 'Table' );
has '+field_name_space' => ( default => sub { ['ShopDb::Field', 'UMPhysics::Field'] } );
has '+field_traits' => ( default => sub { ['UMPhysics::FormHandler::AuthTrait', 'ShopDb::Form::FieldTrait'] } );
has 'nowrap' => ( isa => 'Bool', is => 'rw', default => 0 );
# Whether or not to display help message TDs
# Help messages are added to field definitions as help_message => '<message>'
has 'show_help' => ( isa => 'Bool', is => 'rw', default => 0 );
# The maximum width of help message TDs in pixels
has 'help_message_width' => ( isa => 'Int', is => 'rw', default => 300 );

has 'id_prefix' => ( isa => 'Str', is => 'rw', default => '' );

sub BUILD {
    my $self = shift;

    # Ensure field auth has been determined
    $self->_auth_process;
}

sub html_attributes {
    my ($self, $field, $type, $attrs, $result) = @_;
    if ($type eq 'label') {
        $attrs->{style} = [ $attrs->{style} ] unless (ref $attrs->{style});
        push(@{$attrs->{style}}, 'font-weight:bold;');
        push(@{$attrs->{style}}, 'color:red;') if ($field->has_errors);
    }
    return $attrs;
}

sub custom_build_id {
    my $self = shift;
    my $html_prefix = ( $self->form && $self->form->html_prefix ) ? $self->form->name . "." : '';
    my $id_prefix = $self->form && defined $self->form->id_prefix ? $self->form->id_prefix : '';
    return $html_prefix . $id_prefix . $self->full_name;
}

sub build_update_subfields {{
    all => { build_id_method => \&custom_build_id },
}}

# Returns today in YYYY-MM-DD format
sub today {
    my @time = localtime();
    return strftime('%Y-%m-%d', @time);
}

no HTML::FormHandler::Moose;
1;
