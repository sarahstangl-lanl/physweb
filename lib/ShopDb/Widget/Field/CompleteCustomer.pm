package ShopDb::Widget::Field::CompleteCustomer;

use Moose::Role;
use namespace::autoclean;
use HTML::FormHandler::Render::Util ('process_attrs');

with 'HTML::FormHandler::Widget::Field::Text' => { -excludes => 'render_element' };

sub render_element {
    my $self = shift;
    my $result = shift || $self->result;

    my $m = HTML::Mason::Request->instance or die 'No mason';

    my $t;
    my $output = '<input type="' . $self->input_type . '" name="'
        . $self->html_name . '" id="' . $self->id . '"';
    $output .= qq{ size="$t"} if $t = $self->size;
    $output .= qq{ maxlength="$t"} if $t = $self->maxlength;

    my $fif = $self->fif;
    my $value = $fif || '';
    my $uid = $value || '';

    if (my $customer = $fif) {
        if (ref($customer) eq 'ShopDb::Schema::Result::Customers') {
            $uid = $customer->directory_uid || '';
            if ($self->readonly) {
                $value = $customer->directory->display_name . " <" . $customer->directory->email . ">";
            }
            else {
                $value = $uid;
            }
        }
        else {
            die "Must be passed a ShopDb::Schema::Result::Customers object for field " . $self->name . ", not " . $customer;
        }
    }

    $output .= ' value="' . $self->html_filter($value) . '"';
    $output .= process_attrs($self->element_attributes($result));
    $output .= ' />';

    if (!$self->readonly) {
        $output .= $m->scomp('/mason/ajax/complete_customer.comp', id => $self->id, name => $self->html_name, uid => $uid, prefix => $self->prefix, required => $self->required, no_add_button => $self->no_add_button, include_shop_customers => $self->include_shop_customers);
    }
    else {
        $output .= '<input type="hidden" name="' . $self->html_name . '_uid" id="' . $self->html_name . '_uid" value="' . ($fif ? $fif->directory_uid || '' : '') . '" />';
    }

    return $output;
}

1;
