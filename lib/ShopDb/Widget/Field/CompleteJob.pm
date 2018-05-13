package ShopDb::Widget::Field::CompleteJob;

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
    $output .= ' value="' . $self->html_filter($result->fif ? ($self->readonly ? $m->comp('/mason/ajax/job_to_jobfinder.comp', job_id => $result->fif) : $result->fif) : '') . '"';
    $output .= process_attrs($self->element_attributes($result));
    $output .= ' />';

    if (!$self->readonly) {
        $output .= $m->scomp('/mason/ajax/complete_job.comp',
                            id => $self->id,
                            name => $self->html_name,
                            recent => $self->recent,
                            dropdown_ids => $self->dropdown_ids,
                            ddParamName => $self->ddParamName,
                            no_dropdown_button => $self->no_dropdown_button,
                            job_id => $result->fif);
    }

    return $output;
}

1;
