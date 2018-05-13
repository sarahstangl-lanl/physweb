package ShopDb::Form::RowEditor;

use HTML::FormHandler::Moose;
use HTML::FormHandler::Merge ('merge');

extends 'ShopDb::Form::Base';

has '+widget_form' => ( default => 'Simple' );
has '+widget_wrapper' => ( default => 'Simple' );

has '+auth' => ( default => sub { sub {
    my ($auth, $form) = @_;
    return $auth->{'foreman'} || $auth->{'machinist_id'};
}} );

has 'job_item' => ( is => 'ro', required => 1 );

sub build_update_subfields {
    my $self = shift;
    return merge( { all => { tags => { no_wrapped_label => 1 }, do_label => 0 }, }, $self->next::method(@_) );
}

sub html_attributes {
    my ($self, $obj, $type, $attr, $result) = @_;
    if ($type eq 'form_element') { # Form element
        $attr->{style} = 'position:absolute;top:0;left:0';
    }
    if ($type eq 'element') { # Input element
        if ($obj->readonly) {
            $attr->{style} = 'background-color:#DDD';
        }
        else {
            $attr->{style} = 'background-color:#FFF' unless ($obj->disabled);
        }
    }
    if ($type eq 'wrapper') { # Field wrapper
        $attr->{id} = 're_' . $obj->id;
        $attr->{style} = 'display:none';
    }
    return $attr;
}

no HTML::FormHandler::Moose;

1;
