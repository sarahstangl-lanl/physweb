package ShopDb::Form::ChargeLineBulkUpdate;

use HTML::FormHandler::Moose;
extends 'ShopDb::Form::Base';

has '+widget_form' => ( default => 'Simple' );
has '+widget_wrapper' => ( default => 'None' );
has '+style' => ( default => 'display:inline' );
has '+action' => ( default => 'charge_lines_update.html' );
has 'prefix' => ( isa => 'Str', is => 'rw', required => 1 );
has 'type' => ( isa => 'Str', is => 'rw', predicate => 'has_type', clearer => 'clear_type' );
has 'finalized' => ( isa => 'Bool', is => 'rw', predicate => 'has_finalized', clearer => 'clear_finalized' );
has 'charge_lines_table_id' => ( isa => 'Str', is => 'rw', required => 1 );
has 'job_item' => ( isa => 'ShopDb::Schema::Result::Jobs', is => 'rw' );
has 'success_callback' => ( isa => 'Str', is => 'rw', predicate => 'has_success_callback' );
has 'reset_on_success' => ( isa => 'Bool', is => 'rw', default => 0 );

sub BUILD {
    my $self = shift;
    for my $field ($self->sorted_fields) {
        $field->id($self->prefix . $field->id);
    }
    $self->name($self->prefix . 'bulk_update');
    $self->field('job_id')->dropdown_ids([ $self->prefix . 'parent_job_id' ]);
    $self->field('action')->options();
    if ($self->job_item) {
        $self->field('parent_job_id')->value($self->job_item->parent_job_id || $self->job_item->job_id);
    }
}

sub html_attributes {
    my ($self, $obj, $type, $attr, $result) = @_;
    my $mod_attr = $self->next::method($obj, $type, $attr, $result);
    $attr = $mod_attr if (ref $mod_attr eq 'HASH');
    if ($type eq 'form_element') { # Form tag
        $attr->{autocomplete} = 'off';
    }
    return $attr;
}

has_field 'action' => (
    type => 'Select',
    empty_select => ' ',
    build_javascript => sub {
        my $self = shift;
        my $id = $self->id;
        my $job_id_div = $self->form->prefix . "job_id_div";
        my $output = "var $id = \$('$id');\n";
        $output .= "function ${id}_onchange() {\n";
        $output .= "    if ($id.value == 'move') {\n";
        $output .= "        \$('$job_id_div').setStyle({ display: 'inline-block' });\n";
        $output .= "    }\n    else {\n";
        $output .= "        \$('$job_id_div').setStyle({ display: 'none' });\n";
        $output .= "    }\n}\n";
        $output .= "    $id.observe('change', ${id}_onchange);\n";
        return $output;
    },
);

sub options_action {
    my $self = shift;
    my $options = [ ];
    push(@$options, { value => 'finalize', label => 'Finalize' }) unless ($self->has_finalized && $self->finalized);
    push(@$options, { value => 'unfinalize', label => 'Unfinalize' }) unless ($self->has_finalized && !$self->finalized);
    push(@$options, { value => 'active', label => 'Mark Active' });
    push(@$options, { value => 'inactive', label => 'Mark Inactive' });
    push(@$options, { value => 'move', label => 'Move' });
    return $options;
}

has_field 'job_id' => (
    type => '+CompleteJob',
    style => 'width:200px;',
    ddParamName => 'job_id',
);

has_field 'parent_job_id' => (
    type => 'Hidden',
);

has_field 'submit' => (
    type => 'Submit',
    value => 'Go',
);

sub render {
    my $self = shift;
    my $prefix = $self->prefix;
    my $form_id = $self->name;
    my $job_id_div = $self->form->prefix . "job_id_div";
    my $charge_lines_table_id = $self->charge_lines_table_id;
    my $output = $self->render_start;
    $output .= $self->field('action')->render;
    $output .= $self->field('parent_job_id')->render;
    $output .= '<span id="' . $self->prefix . 'job_id_div" style="display:none">';
    $output .= $self->field('job_id')->render;
    $output .= '</span>';
    $output .= $self->field('submit')->render;
    $output .= $self->render_end;
    $output .= qq[
<script type="text/javascript">
\$('$form_id').observe('submit', ${prefix}onBulkUpdateSubmit);
function ${prefix}onBulkUpdateSubmit(e) {
    //Get selected lines
    selectedLineIDs = \$('$charge_lines_table_id').roweditor.getSelectedRows().collect(function(tr) {
        return tr.getAttribute('data-type') + '_' + tr.getAttribute('data-line_id');
    });
    \$('] . $self->field('submit')->id . qq[').insert({ after: new Element('img', {src: '/images/ajax-loader.gif'}).setStyle({
            marginBottom: '-3px',
            paddingLeft: '5px'
        })});
    e.findElement('form').request({
        parameters: {
            'line_ids': selectedLineIDs
        },
        asynchronous: true,
        onSuccess: ${prefix}onBulkUpdateSuccess.bind(this),
        onFailure: function () { \$(']. $self->field('submit')->id . qq[').next().remove(); alert('There was problem submitting your request. Please try again.'); }
    });
    e.stop();
}

function ${prefix}onBulkUpdateSuccess(transport) {
    \$(']. $self->field('submit')->id . qq[').next().remove();
    var response;
    try {
        response = transport.responseText.evalJSON();
    } catch (e) { }

    if (response) {
        if (response.result == 'ok') {
            ] . ($self->has_success_callback ? $self->success_callback : 'window.location.reload();') . ($self->reset_on_success ? qq[
            \$('$form_id').reset();
            \$('$job_id_div').setStyle({ display: 'none' });] : '') . qq[
        }
        else
            alert('There was an error during your request: ' + response.message);
    }
    else
        alert('There was an error processing the request response. Please reload the page.');
}
</script>];
    return $output;
}

no HTML::FormHandler::Moose;
1;
