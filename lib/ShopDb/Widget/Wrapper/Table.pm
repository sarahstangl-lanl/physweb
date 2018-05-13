package ShopDb::Widget::Wrapper::Table;

use Moose::Role;
with 'HTML::FormHandler::Widget::Wrapper::Base';
use HTML::FormHandler::Render::Util ('process_attrs');

sub label_wrapper_attributes {
    my ($self, $result) = @_;
    $result ||= $self->result;
    my $attr = {
        align => 'right',
        style => [ 'padding-top: 4px;' ],
        valign => 'top',
    };
    $attr->{nowrap} = 'nowrap' if ($self->has_flag('nowrap') || $self->form->has_flag('nowrap'));
    my $mod_attr = $self->form->html_attributes($self, 'label_wrapper', $attr, $result) if ($self->form);
    return ref $mod_attr eq 'HASH' ? $mod_attr : {};
}

sub element_wrapper_attributes {
    my ($self, $result) = @_;
    $result ||= $self->result;
    my $attr = {
        valign => 'top',
    };
    if ($self->type eq 'Submit') {
        $attr->{colspan} = 2;
        $attr->{align} = 'right';
    }
    $attr->{nowrap} = 'nowrap' if ($self->has_flag('nowrap') || $self->form->has_flag('nowrap'));
    my $mod_attr = $self->form->html_attributes($self, 'element_wrapper', $attr, $result) if ($self->form);
    return ref $mod_attr eq 'HASH' ? $mod_attr : {};
}

sub wrap_field {
    my ( $self, $result, $rendered_widget ) = @_;

    return $rendered_widget if ( $self->has_flag('is_compound') && $self->get_tag('no_compound_wrapper') );

    my $output .= $self->get_tag('before_wrapper');
    $output .= "\n<tr" . process_attrs($self->wrapper_attributes($result)) . ">";
    if ( $self->has_flag('is_compound') ) {
        $output .= '<td' . process_attrs($self->label_wrapper_attributes($result)) . '>' . $self->do_render_label($result) . '</td></tr>';
    }
    elsif ( $self->do_label && length( $self->label ) > 0 ) {
        $output .= '<td' . process_attrs($self->label_wrapper_attributes($result)) . '>' . $self->do_render_label($result) . '</td>';
    }
    if ( !$self->has_flag('is_compound') ) {
        $output .= '<td' . process_attrs($self->element_wrapper_attributes($result)) . '>';
    }
    $output .= $self->get_tag('before_element');
    $output .= $rendered_widget;
    $output .= $self->get_tag('after_element');
    $output .= qq{\n<div class="error_message">$_</div>} for $result->all_errors;
    if ( $self->has_build_javascript ) {
        $output .= "<script type=\"text/javascript\">\n" . $self->build_javascript->($self) . "\n</script>\n";
    }
    if ( !$self->has_flag('is_compound') ) {
        $output .= '</td>';
        if ( $self->form->show_help ) {
            $output .= '<td style="vertical-align: top; padding-top: 6px; max-width: ' . $self->form->help_message_width . 'px">';
            if ($self->has_help_message) {
                $output .= $self->help_message;
            }
            $output .= '</td>';
        }
        $output .= "</tr>\n";
    }
    $output .= $self->get_tag('after_wrapper');
    return $output;
}

use namespace::autoclean;
1;
