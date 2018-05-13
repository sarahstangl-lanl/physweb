package UMPhysics::Widget::Field::CompletePeople;

use Moose::Role;
use namespace::autoclean;
use HTML::FormHandler::Render::Util ('process_attrs');

sub render {
    my $self = shift;
    my $result = shift || $self->result;
    my $t;

    my $m = HTML::Mason::Request->instance or die 'No mason';

    my $rendered = $self->html_filter($result->fif);
    my $output = '<input type="' . $self->input_type . '" name="'
        . $self->html_name . '" id="' . $self->id . '"';
    $output .= qq{ size="$t"} if $t = $self->size;
    $output .= qq{ maxlength="$t"} if $t = $self->maxlength;
    $output .= ' value="' . $self->html_filter($self->readonly ? $m->comp('/mason/ajax/uid_to_peoplefinder.comp', uid => $result->fif) : $result->fif) . '"';
    $output .= process_attrs($self->element_attributes($result));
    $output .= ' />';
    $output .= $m->scomp('/mason/ajax/complete_people.comp', id => $self->id, name => $self->html_name, uid => $result->fif, include_shop_customers => $self->include_shop_customers) unless ($self->readonly);

    return $self->wrap_field( $result, $output );
}

1;
