package ShopDb::Widget::Field::CompleteAccount;

use Moose::Role;
use namespace::autoclean;
use HTML::FormHandler::Render::Util ('process_attrs');

with 'HTML::FormHandler::Widget::Field::Text' => { -excludes => 'render_element' };

sub render_element {
    my $self = shift;
    my $result = shift || $self->result;

    my $m = HTML::Mason::Request->instance or die 'No mason';

    my $job_item = $self->form->item;
    my $item = $job_item ? $job_item->account : undef;
    $item ||= $self->form->schema->resultset('Accounts')->new({});
    my $t;
    my $output = '<input type="' . $self->input_type . '" name="'
        . $self->html_name . '" id="' . $self->id . '"';
    $output .= qq{ size="$t"} if $t = $self->size;
    $output .= qq{ maxlength="$t"} if $t = $self->maxlength;
    $output .= ' value="' . $self->html_filter($result->fif ? ($self->readonly ? $m->comp('/mason/ajax/account_to_accountfinder.comp', account => $result->fif) : $result->fif) : '') . '"';
    $output .= process_attrs($self->element_attributes($result));
    $output .= ' />';
    $output .= $m->scomp('/mason/ajax/complete_account.comp', id => $self->id, name => $self->html_name, account => $result->fif, dropdown_ids => $self->dropdown_ids, no_add_button => $self->no_add_button, no_dropdown_button => $self->no_dropdown_button ) if !$self->readonly;
    $output .= '<table class="efs_chartstring"><tr><th>FUND</th><th>DEPTID</th><th>PROGRAM</th><th>PROJECT</th></tr>';
    $output .= '<tr><td class="efs_fund" id="' . $self->id . '_fund">' . ($item->fund_code || '&nbsp;') . '</td><td class="efs_deptid" id="' . $self->id . '_deptid">' . ($item->deptid || '&nbsp;') . '</td><td class="efs_prgm" id="' . $self->id . '_prgm">' . ($item->program_code || '&nbsp;') . '</td><td class="efs_proj" id="' . $self->id . '_proj">' . ($item->project_id || '&nbsp;') . '</td></tr></table>';
    $output .= '<table class="efs_chartstring"><tr><th>EMPLID</th><th>CF1</th><th>CF2</th></tr>';
    $output .= '<tr><td class="efs_emplid" id="' . $self->id . '_emplid">' . ($item->chartfield3 || '&nbsp;') . '</td><td class="efs_cf1" id="' . $self->id . '_cf1">' . ($item->chartfield1 || '&nbsp;') . '</td><td class="efs_cf2" id="' . $self->id . '_cf2">' . ($item->chartfield2 || '&nbsp;') . '</td></tr></table>';
    return $output;
}

1;
