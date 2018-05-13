package ShopDb::Widget::Field::DateSelect;

use Moose::Role;
use namespace::autoclean;

with 'HTML::FormHandler::Widget::Field::Select';

around 'render_element' => sub {
    my $orig = shift;
    my $self = shift;
    my $output = $self->$orig(@_);
    (my $base_id = $self->id) =~ s/\..*$//;
    $output .= '
        <script type="text/javascript">
        function checkType' . ucfirst($base_id) . '(type) {
            node = $("' . $base_id . '.end").parentNode.parentNode;
            if (type == "between") {
                node.style.display = "";
            } else {
                node.style.display = "none";
            }
        }
        </script>'."\n";
    return $output;
};

1;
