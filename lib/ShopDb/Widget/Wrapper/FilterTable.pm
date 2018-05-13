package ShopDb::Widget::Wrapper::FilterTable;

use Moose::Role;
with 'HTML::FormHandler::Widget::Wrapper::Base';

sub render_label_alt {
    my $self = shift;
    return '<label class="label" for="' . $self->id . '">' . $self->label . ' </label>';
}

sub wrap_field {
    my ( $self, $result, $rendered_widget ) = @_;
    my $class  = $self->render_class($result);
    if ($self->has_flag('hide')) {
        $class .= ' style="display:none"' unless $self->form->processed && $self->result->parent->value->{type} eq 'between';
    }
    my $output = '';
    my $align = $self->has_flag('align') ? ' align=' . $self->align : '';
    if (!$self->can('wrapper_start') || $self->wrapper_start) {
        $output = "\n<tr$class>";
    }
    if ( $self->has_flag('is_compound') ) {
        $output .= '<td align="right"><b>' . $self->render_label_alt . '</b></td><td></td></tr>';
    }
    elsif ( !$self->has_flag('no_render_label') && $self->label ) {
        $output .= '<td align="right" style="padding-top: 5px;" valign="top"><b>' . $self->render_label_alt . '</b></td>';
    }
    if ( !$self->has_flag('is_compound') ) {
        $output .= '<td></td>' if $self->has_flag('empty_cell_before');
        $output .= "<td$align>";
    }
    $output .= $rendered_widget;
    $output .= qq{\n<span class="error_message">$_</span>} for $result->all_errors;
    if ( !$self->has_flag('is_compound') ) {
        $output .= "</td>";
    }
    if (!$self->can('wrapper_end') || $self->wrapper_end) {
        if ( !$self->has_flag('is_compound') ) {
            $output .= "</tr>\n";
        }
    }
    return $output;
}

use namespace::autoclean;
1;
