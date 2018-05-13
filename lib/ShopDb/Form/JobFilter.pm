package ShopDb::Form::JobFilter;

use HTML::FormHandler::Moose;
extends 'ShopDb::Form::Base';

has '+widget_wrapper' => ( default => 'FilterTable' );
has '+widget_form' => ( default => 'Simple' );

has '+item_class' => ( default => 'Jobs' );

has 'rs' => ( isa => 'ScalarRef[DBIx::Class::ResultSet]', is => 'rw', required => 1 );

has_field 'job_id' => (
    label => 'Job Number',
    type => 'Integer',
    size => '17',
    element_attr => { style => 'width: 200px;' },
);

has_field 'filemaker_job_id' => (
    label => 'Filemaker Job #',
    type => 'Text',
    size => '17',
    element_attr => { style => 'width: 200px;' },
);

has_field 'customer_po_num' => (
    label => 'Customer PO#',
    type => 'Text',
    size => '17',
    element_attr => { style => 'width: 200px;' },
);

has_field 'project_name' => (
    label => 'Project Name',
    size => '17',
    element_attr => { style => 'width: 200px;' },
);

has_field 'status' => (
    label => 'Job Status',
    type => 'Select',
    label_column => 'label',
    sort_column => 'sort_order',
    empty_select => '-- Status --',
);

has_field 'creation_date' => (
    label => 'Creation Date',
    type => '+DateRange',
);

has_field 'in_date' => (
    type => '+DateRange',
    label => 'In Date',
);

has_field 'need_date' => (
    type => '+DateRange',
    label => 'Need Date',
);

has_field 'approved_date' => (
    label => 'Approved Date',
    type => '+DateRange',
);

has_field 'finish_date' => (
    type => '+DateRange',
    label => 'Finish Date',
);

has_field 'ship_date' => (
    label => 'Ship Date',
    type => '+DateRange',
);

has_field 'modified_date' => (
    label => 'Modified Date',
    type => '+DateRange',
);

has_field 'machinists' => (
    type => 'Multiple',
    label_column => 'shortname',
);

sub options_machinists {
    my $self = shift;
    # Put inactive machinists at the bottom of the list
    my @machinists = $self->schema->resultset('Machinists')->with_directory_info->search({ }, { order_by => [ { -desc => 'active' }, 'shortname' ] });
    my @options;
    for (@machinists) {
        push(@options, {
            label => $_->get_column('shortname'),
            value => $_->machinist_id,
        });
    }
    return @options;
}

has_field 'entry_machinist' => (
    label => 'Entry Machinist',
    type => 'Select',
    empty_select => ' -- ',
    label_column => 'shortname',
    options_method => sub { shift->form->field('machinists')->options },
);
has_field 'customer_id' => (
    label => 'Customer',
    type => '+CompleteCustomer',
    no_add_button => 1,
);
has_field 'pi_id' => (
    label => 'PI',
    type => '+CompleteCustomer',
    no_add_button => 1,
);
has_field 'contact_number' => (
    label => 'Contact Phone #',
    type => 'Text',
);
has_field 'account_key' => (
    label => 'EFS Account',
    type => '+CompleteAccount',
    dropdown_ids => [ ],
    no_add_button => 1,
    no_dropdown_button => 1,
);
has_field 'bill_address_id' => (
    label => 'Billing Address',
    type => '+CompleteAddress',
    no_add_button => 1,
    no_dropdown_button => 1,
);
has_field 'ship_address_id' => (
    label => 'Shipping Address',
    type => '+CompleteAddress',
    no_add_button => 1,
    no_dropdown_button => 1,
);
has_field 'ship_method' => (
    label => 'Shipping Method',
    type => 'Text',
);
has_field 'property_id' => (
    label => 'Asset ID',
    type => 'Text',
);
has_field 'parent_job_id' => (
    label => 'Parent Job',
    type => '+CompleteJob',
    no_dropdown_button => 1,
);
has_field 'external' => (
    label => 'External',
    type => 'Select',
    options => [ { label => 'Yes', value => 1 }, { label => 'No', value => 0 } ],
    empty_select => ' -- ',
);

has_field 'reset' => (
    type => 'Submit',
    widget_wrapper => 'None',
    value => 'Reset',
    javascript => 'onclick="return "',
);

has_field 'filter_submit' => (
    type => 'Submit',
    widget_wrapper => 'None',
    value => 'Search',
);

sub update_model {
    my $self = shift;
    use Data::Dumper;
    my $fields = $self->fields;
    my $rs = ${$self->rs};
    foreach my $field (@$fields) {
        warn "Type for field " . $field->name . ": " . $field->type;
        next unless ($field->fif || $field->fif ne '');
        if ($field->type eq '+DateRange') {
            if ($field->fif->{type} eq 'equals') {
                if ($field->fif->{start}) {
                    $rs = $rs->search({
                        'me.' . $field->name => $field->fif->{start},
                    });
                }
            }
            elsif ($field->fif->{type} eq 'before') {
                if ($field->fif->{start}) {
                    $rs = $rs->search({
                        'me.' . $field->name => { '<', $field->fif->{start} },
                    });
                }
            }
            elsif ($field->fif->{type} eq 'after') {
                if ($field->fif->{start}) {
                    $rs = $rs->search({
                        'me.' . $field->name => { '>', $field->fif->{start} },
                    });
                }
            }
            elsif ($field->fif->{type} eq 'between') {
                if ($field->fif->{start} && $field->fif->{end}) {
                    my @dates = sort ($field->fif->{start}, $field->fif->{end});
                    $rs = $rs->search({
                        'me.' . $field->name => { -between => \@dates },
                    });
                }
            }
            else {
                die "Unknown " . $field->name . " type '" . $field->fif->{type} . "'";
            }
        }
        elsif ($field->name eq 'machinists') {
            if ((ref $field->fif eq 'ARRAY' && @{$field->fif}) || !ref $field->fif) {
                $rs = $rs->search({
                    'machinist.machinist_id' => $field->fif,
                }, {
                    join => 'job_assignments',
                });
            }
        }
        elsif ($field->name eq 'status') {
            $rs = $rs->search({
                'me.job_status_id' => $field->fif,
            });
        }
        elsif ($field->name eq 'entry_machinist') {
            $rs = $rs->search({
                'me.entry_machinist_id' => $field->fif,
            });
        }
        elsif ($field->type =~ /^(Integer|Select|\+CompleteAddress|\+CompleteAccount|\+CompleteJob)$/) {
            $rs = $rs->search({
                'me.' . $field->name => $field->fif,
            });
        }
        elsif ($field->type eq 'Text') {
            $rs = $rs->search({
                'me.' . $field->name => { -like => '%' . $field->fif . '%' },
            });
        }
        elsif ($field->type eq '+CompleteCustomer') {
            $rs = $rs->search({
                'me.' . $field->name => $field->fif->id,
            });
        }
        elsif ($field->type eq 'Submit') {
            # Noop
        }
        else {
            die "Unhandled filter type " . $field->type . ' for field ' . $field->name;
        }
    }
    ${$self->rs} = $rs;
    warn Dumper($rs->as_query);
}

sub html_attributes {
    my ($self, $obj, $type, $attrs, $result) = @_;
    if ($type eq 'element') {
        warn "field " . $obj->name . " has type " . $obj->type . " and element attr style: " . $obj->exists_element_attr('style');
        return { style => 'width:250px;' } unless ($obj->type =~ /(Multiple|Select|Date)/ || $obj->exists_element_attr('style'));
    }
}

sub render {
    my $self = shift;
    # Names of fields to display in quick search form
    my @basic_fields = qw/job_id filemaker_job_id project_name status customer_po_num machinists/;
    # Names of button fields
    my @buttons = qw/reset filter_submit/;
    # List of fields to display in advanced search form (those not in @basic_fields or @buttons)
    my @advanced_fields = grep { my $name = $_->name; ! grep { $_ eq $name } (@basic_fields, @buttons) } $self->sorted_fields;

    # Fields to show to customers
    my @customer_field_globs = (qw/^job_id status customer_po_num project_name date customer_id pi_id account_key address property_id/);

    # Filter fields unless foreman or machinist
    unless ($self->auth_args->{foreman} || $self->auth_args->{machinist_id}) {
        @basic_fields = grep { my $field = $_; grep { warn "glob: $_"; $field =~ /$_/ } @customer_field_globs } @basic_fields;
        @advanced_fields = grep { my $field = $_; grep { $field->name =~ /$_/ } @customer_field_globs } @advanced_fields;
    }

    # Check for advanced fields being filled in and switch to adavanced form if necessary
    my $advanced = 0;
    for (@advanced_fields) {
        if ($_->type eq '+DateRange') {
            if ($_->fif && ($_->fif->{start} || $_->fif->{end})) {
                $advanced = 1;
                last;
            }
        }
        elsif (defined $_->fif && $_->fif ne '') {
            $advanced = 1;
            last;
        }
    }
    my $type = $advanced ? 'Advanced' : 'Quick';
    my $action = $self->action || '';
    my $advanced_fields_list = join(', ', map { '$("' . $_->id . '")' } map { $_->has_flag('is_compound') ? $_->fields : $_ } @advanced_fields);
    my $m = HTML::Mason::Request->instance or die 'No mason';
    my $output = $m->comp('/mason/ajax/js.comp');
    $output .= <<END
<div id="shopdb-job-search" style="background-color: #DDD;padding:0 10px 10px 10px;border-radius: 8px;border:1px solid black;">
<h4 id="shopdb-search-title" style="padding: 5px 0 5px 0">$type Job Search</h4>
<form id="shopdb-search-form" method="post" name="search" action="$action"><table><tr><td style="width:110px;"></td><td></td></tr>
<script language="javascript">
function shopdbToggleFields() {
    var toggleLink = \$('shopdb-search-toggle');
    var searchTitle = \$('shopdb-search-title');
    toggleLink.blur();
    if (searchTitle.textContent == 'Quick Job Search') {
        Effect.BlindDown('shopdb-advanced-fields');
        toggleLink.textContent = 'Quick Search';
        searchTitle.textContent = 'Advanced Job Search';
    }
    else {
        Effect.BlindUp('shopdb-advanced-fields');
        toggleLink.textContent = 'Advanced Search';
        searchTitle.textContent = 'Quick Job Search';
        shopdbClearAdvancedFields();
    }
}

function shopdbClearAdvancedFields() {
    shopdbClearForm(\$A([$advanced_fields_list]));
}

function shopdbClearForm(elements) {
    if (!elements)
        elements = \$('shopdb-search-form').elements;
    for(i=0; i<elements.length; i++) {
        field_type = elements[i].type.toLowerCase();
        switch(field_type) {
            case "text":
            case "password":
            case "textarea":
            case "hidden":
                elements[i].value = "";
                break;
            case "radio":
            case "checkbox":
                if (elements[i].checked) {
                    elements[i].checked = false;
                }
                break;
            case "select-one":
                elements[i].selectedIndex = 0;
                if (elements[i].onchange) {
                    elements[i].onchange();
                }
                break;
            case "select-multiple":
                elements[i].selectedIndex = -1;
                break;
            default:
                break;
        }
    }
    return false;
}
</script>
END
;
    for (@basic_fields) {
        my $field = $self->field($_);
        $output .= $field->render if ($field->has_read_auth);
    }
    $output .= '</table><div id="shopdb-advanced-fields" ' . ($advanced ? '' : 'style="display:none"') . '><table><tr><td style="width:110px;"></td><td></td></tr>';
    for (@advanced_fields) {
        $output .= $_->render if ($_->has_read_auth);
    }
    $output .= '
</table></div>
<div style="width: 100%; text-align: right; margin: 5px 0 0 -15px; padding-top: 5px;">
<span style="padding-right: 8px;"><input type="button" name="reset" value="Reset" onclick="return shopdbClearForm()" /></span>
<span><input class="button" type="submit" onclick="document.search.submit()" name="filter_submit" value="Search"></span>
<div style="padding-top: 10px; width: 100%; text-align: right;"><a href="#" id="shopdb-search-toggle" onclick="shopdbToggleFields()">' . ($advanced ? 'Quick' : 'Advanced') . ' Search</a></div>
</div></div></form>';
    return $output;
}

no HTML::FormHandler::Moose;
1;
