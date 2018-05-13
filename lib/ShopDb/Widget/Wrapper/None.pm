package ShopDb::Widget::Wrapper::None;
# ABSTRACT: wrapper that doesn't wrap (but has been extended to support build_javascript and all_errors methods)

use Moose::Role;

sub wrap_field {
    my ($self, $result, $rendered_widget) = @_;
    my $output = $rendered_widget;
    $output .= qq{\n<div class="error_message">$_</div>} for $result->all_errors;
    if ( $self->has_build_javascript ) {
        $output .= "<script type=\"text/javascript\">\n" . $self->build_javascript->($self) . "\n</script>\n";
    }
    return $output;
}

use namespace::autoclean;
1;
