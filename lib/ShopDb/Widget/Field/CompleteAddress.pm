package ShopDb::Widget::Field::CompleteAddress;

use Moose::Role;
use namespace::autoclean;
use HTML::FormHandler::Render::Util ('process_attrs');

with 'HTML::FormHandler::Widget::Field::Textarea' => { -excludes => 'render_element' };

sub render_element {
    my $self = shift;
    my $result = shift || $self->result;

    my $m = HTML::Mason::Request->instance or die 'No mason';

    my $fif  = $self->html_filter($result->fif ? ($self->readonly ? $m->comp('/mason/ajax/address_to_addressfinder.comp', address_id => $result->fif) : $result->fif) : '');
    my $id   = $self->id;
    my $cols = $self->cols || 10;
    my $rows = $self->rows || 5;
    my $name = $self->html_name;
    my $output =
        qq(<textarea name="$name" id="$id")
        . process_attrs($self->element_attributes($result))
        . qq( rows="$rows" cols="$cols">$fif</textarea>);
    if (!$self->readonly) {
        $output .= $m->scomp('/mason/ajax/complete_address.comp',
                            id => $self->id,
                            name => $self->html_name,
                            no_dropdown_button => $self->no_dropdown_button,
                            no_add_button => $self->no_add_button,
                            dropdown_ids => $self->dropdown_ids,
                            ddParamName => $self->ddParamName,
                            address_id => $result->fif);
    }
    return $output;
}

1;
