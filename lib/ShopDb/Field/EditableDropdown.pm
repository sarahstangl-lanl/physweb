package ShopDb::Field::EditableDropdown;

use Moose;

extends 'HTML::FormHandler::Field::Select';

has '+empty_select' => ( default => '' );

before 'get_tag' => sub {
    my $self = shift;
    return if ($self->tag_exists('after_element'));
    $self->set_tag(after_element => sub {
        warn "after_element";
        my $self = shift;
        my $id = $self->id;
        (my $html_name = $self->html_name) =~ s/_display$//;
        my $output = qq[<input style="display:none" name="$html_name" id="${id}_input" value="] . $self->html_filter($self->fif) . '" />';
        $output .= qq[
<script text="text/javascript">
select = \$('$id');
select.onEdit = function() {
    \$('${id}_input').value = this.value;
}.bind(select);
select.onAbort = function() {
    \$('${id}_input').setStyle({ display: 'none' });
    \$('${id}_input').value = '';
};
function updateSelect$id(select) {
    input_$id = \$('${id}_input');
    if (select.value == 'New...') {
        input_$id.setStyle({ display: 'inline', position: 'absolute', border: select.getStyle('border') }).clonePosition(select.parentNode, { setHeight: false });
        input_$id.value = '';
    }
    else {
        input_$id.value = select.value;
    }
}
</script>];
        return $output;
    });
};

sub build_html_name {
    my $self = shift;
    my $prefix = ( $self->form && $self->form->html_prefix ) ? $self->form->name . "." : '';
    return $prefix . $self->full_name . '_display';
}

sub build_element_attr {
    my $self = shift;
    return {
        onchange => 'updateSelect' . $self->id . '(this)',
    };
}

after '_load_options' => sub {
    my $self = shift;
    $self->options([ @{ $self->{options} }, { value => 'New...', label => 'New...' } ]);
};

sub _inner_validate_field { };

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;
