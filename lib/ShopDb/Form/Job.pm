package ShopDb::Form::Job;

use namespace::autoclean;
use HTML::FormHandler::Moose;
use Mail::Sendmail;

extends 'ShopDb::Form::Base';

has '+item_class' => ( default => 'Jobs' );

has '+auth_field_list' => (
    default => sub { {
        customer    => '_customer_id',
        pi          => '_customer_id',
        machinists  => '_machinist_id',
        entry_machinist => '_machinist_id',
    } }
);

has '+widget_form' => ( default => 'Simple' );
has '+nowrap' => ( default => 1 );

around 'update_model' => \&around_update_model;

sub BUILD {
    my $self = shift;

    my $auth_args = $self->auth_args;

    # Require entry_machinist if on job entry PC
    if ($auth_args->{'job_entry_pc'}) {
        warn "Marking entry_machinist required";
        $self->field('entry_machinist')->required(1);
    }

    # Set entry_machinist to machinist_id if current user is a machinist and creating job
    if (!$self->item && $auth_args->{'machinist_id'}) {
        warn "Setting entry_machinist to " . $auth_args->{'machinist_id'};
        $self->field('entry_machinist')->default($auth_args->{'machinist_id'});
        $self->field('entry_machinist')->value($auth_args->{'machinist_id'});
    }

    $self->update_active_fields;
}

sub update_active_fields {
    my $self = shift;
    my $auth_args = $self->auth_args;

    # Remove submit buttons from results and mark them inactive unless they have auth
    my (@to_remove, $field);
    foreach ($self->fields) {
        if ($_->type eq 'Submit') {
            $_->noupdate(1);
            if (!$_->has_auth) {
                $_->inactive(1);
                push(@to_remove, $_->name);
            }
        }
    }

    # Hide child jobs unless a parent job or have auth and no parent_job_id
    $field = $self->field('child_jobs');
    if (($self->item && $self->item->parent_job_id) || (!$field->has_auth && (!$self->item || !$self->item->child_jobs->count))) {
        $field->inactive(1);
        push(@to_remove, $field->name);
    }

    # Hide account and mark inactive for non-shop users
    unless ($auth_args->{'shop_person'}) {
        $field = $self->field('account_key');
        $field->inactive(1);
        push(@to_remove, $field->name);
    }

    # Hide parent job name unless a child job or have auth
    $field = $self->field('parent_job_id');
    if ((
      (!$self->item && !$field->value) ||
      ($self->item && !$self->item->parent_job_id)
      ) && !$field->has_auth) {
        $field->inactive(1);
        push(@to_remove, $field->name);
    }
    my @results = $self->results;

    # Filter out results with names in @to_remove
    @results = grep {
        $field = $_;
        # Include only if not found in to_remove
        ! grep { $field->name eq $_ } @to_remove;
    } @results;

    # Store new results
    $self->result->_results(\@results);
}

sub validate {
    my $self = shift;

    # Create status id to label mapping
    my %status_map = map { $_->{value} => $_->{label} } @{ $self->field('status')->options };

    # Update in_date as today if finalizing job or approving at submit time
    my $field = $self->field('in_date');
    if (defined $self->params->{job_finalize} || defined $self->params->{job_approve}) {
        $field->noupdate(0);
        $field->value($self->today);
    }
    elsif (defined $self->params->{job_draft}) {
        $field->noupdate(1);
    }

    # Set entry_machinist if default provided
    $field = $self->field('entry_machinist');
    if (my $default = $field->default) {
        warn "Setting entry_machinist to $default";
        $field->value($default);
        $field->noupdate(0);
    }

    # Set finish_date if setting status to finished
    if ($self->field('status')->value && $status_map{$self->field('status')->value} eq 'Finished' && !($self->item && $self->item->finish_date)) {
        $self->field('finish_date')->value($self->today);
    }

    # Set approved_date to today if approving
    if (defined $self->params->{job_approve} && $self->field('job_approve')->has_auth) {
        $self->field('approved_date')->noupdate(0);
        $self->field('approved_date')->value($self->today);
    }

    # Require need_date if finalizing/approving job or job already finalized
    if (defined $self->params->{job_finalize} || defined $self->params->{job_approve} || ($self->item && $self->item->finalized)) {
        unless ($self->field('need_date')->value) {
            $self->field('need_date')->add_error('Need date is required');
        }
    }

    # Require machinists if approving for production
    if (defined $self->params->{job_approve} && $self->field('job_approve')->has_auth) {
        unless ($self->field('machinists')->value) {
            $self->field('machinists')->add_error('At least machinist is required for Production');
        }
    }

    # Mark parent_job_id active and set value to default if default set
    $field = $self->field('parent_job_id');
    if ($field->default) {
        $field->noupdate(0);
        $field->value($field->default);
    }

    # Mark customer field active if creating item
    $self->field('customer')->noupdate(0) unless ($self->item);

    # Determine automatic job status
    $field = $self->field('status');
    # Allow job to marked as cancelled unless active charge lines
    if (defined $self->params->{job_cancel} || ($field->has_auth && $status_map{$field->value} eq 'Cancelled')) {
        if ($self->item && ($self->item->material_lines->search({ active => 1 })->count || $self->item->labor_lines->search({ active => 1 })->count)) {
            $field->add_error("Jobs cannot be cancelled when there are active charge lines");
        }
    }
    elsif (defined $self->params->{job_draft}) {
        $field->noupdate(0);
        $field->value('Draft');
    }
    elsif (defined $self->params->{job_finalize}) {
        $field->noupdate(0);
        $field->value('Awaiting foreman approval');
    }
    elsif (defined $self->params->{job_approve} || ($self->item && $self->item->approved_date && $status_map{$self->item->job_status_id} eq 'Awaiting assignment' && $self->field('machinists')->has_auth && @{$self->field('machinists')->value || []})) {
        $field->noupdate(0);
        $field->value('In progress');
        # TODO Still need to handle finish date specified at job creation => Awaiting shipping
    }
    elsif ($self->item && $self->item->approved_date && $self->field('machinists')->has_auth && !@{$self->field('machinists')->value || []}) {
        $field->noupdate(0);
        $field->value('Awaiting assignment');
    }
    elsif ($self->field('finish_date')->value || ($self->item && $self->item->finish_date)) {
        $field->noupdate(0);
        if (!$self->item || $self->item->quantity_ordered > $self->item->quantity_shipped) {
            $field->value('Awaiting shipping');
        }
        else {
            $field->value('Shipped');
        }
    }
    # Convert status strings to internal number
    $field->value($field->deflate_value($field->value));

    # Don't update machinists unless they've actually changed
    if ($self->item) {
        $field = $self->field('machinists');
        unless ($field->noupdate) {
            my @cur_machinists = sort $self->item->job_assignments_rs->get_column('machinist_id')->all;
            my @new_machinists = sort @{$field->value || []};
            if (@cur_machinists ~~ @new_machinists) {
                $field->noupdate(1);
            }
        }
    }

    $self->field('modified_date')->value(\'NOW()');
}

sub around_update_model {
    my $orig = shift;
    my $self = shift;
    my @args = @_;

    my @messages_to_send;
    my $mail_params = {
        creation => {
#            To => $customer->directory->email,
        },
        efs_update => {
            To => 'CSE Shop <cseshop@umn.edu>',
        },
    };

    $self->schema->txn_do(sub {

        # Create customer/pi if not in database yet
        foreach my $field (map { $self->field($_); } (qw/customer pi/)) {
            next if ($field->noupdate);
            my $customer = $field->value;
            if ($customer && !$customer->in_storage) {
                my $directory = $customer->directory;
                if ($directory->in_storage) {
                    warn "Form::Job::around_update_model: Directory entry exists for field " . $field->name;
                }
                elsif ($directory->x500 && (my $existing_entry = $self->schema->resultset('DirectoryEntry')->find({ x500 => $directory->x500 }))) {
                    warn "Form::Job::around_update_model: Directory entry with x500 " . $directory->x500 . " already exists for field " . $field->name;
                    $customer->set_column(directory_uid => $existing_entry->uid);
                }
                else {
                    warn "Form::Job::around_update_model: Creating directory entry for field " , $field->name;
                    $directory->insert;
                    $customer->set_column(directory_uid => $directory->uid);
                }
                # Make sure customer entry wasn't already created in loop
                if ($customer->directory_uid && (my $existing_customer = $self->schema->resultset('Customers')->find({ directory_uid => $customer->directory_uid }))) {
                    warn "Form::Job::around_update_model: Customer already created for field " . $field->name;
                    $field->value($existing_customer);
                    $self->fields_set_value;
                    next;
                }
                warn "Form::Job::around_update_model: Creating customer for field " . $field->name;
                $customer->insert;
                # Update auth_args for customer
                if ($field->name eq 'customer' && $self->auth_args->{x500} eq $directory->x500) {
                    warn "Form::Job::around_update_model: Updating auth args for customer";
                    $self->auth_args->{uid} = $directory->uid;
                    $self->auth_args->{customer_id} = $customer->customer_id;
                }
            }
        }

        # Determine which emails to send
#        push(@messages_to_send, 'creation') if (!$self->item);
        push(@messages_to_send, 'efs_update') if ((!$self->item && $self->field('account_key')->value) || ($self->item && $self->field('account_key')->value ne $self->item->account_key));

        # Handle machinists manually to prevent extra deletion/creation audit entries -
        # many-to-many relationships update values by deleting existing bridge entries
        # and then adding new set of bridge entries
        my $field = $self->field('machinists');
        unless ($field->noupdate || !$self->item) {
            my @current_machinists = $self->item->machinists->get_column('machinist_id')->all;
            my %machinists_to_delete = map { $_ => 1 } @current_machinists;
            for my $machinist (@{$field->value}) {
                $self->item->add_to_job_assignments({ machinist_id => $machinist }) unless grep { $_ eq $machinist } @current_machinists;
                $machinists_to_delete{$machinist} = 0;
            }
            for my $machinist (@current_machinists) {
                $self->item->find_related('job_assignments', { machinist_id => $machinist })->delete if $machinists_to_delete{$machinist};
            }
            $field->noupdate(1);
            $self->fields_set_value;
        }

        # Create/update job
        $self->$orig(@args);
    });

    # Send notification email(s)
    foreach my $message_type (@messages_to_send) {
        if ($message_type eq 'creation') {
            sendmail(
                To => 'nick@physics.umn.edu',
                From => 'net@physics.umn.edu',
                Subject => 'Job #' . $self->item->job_id . ' has been created',
                Message => 'Job #' . $self->item->job_id . ' has been created',
            );
        }
        elsif ($message_type eq 'efs_update') {
            my $job = $self->item;
            my $job_id = $job->job_id;
            my $customers = $self->schema->resultset('Customers')->with_directory_info;
            my $display_name = $self->auth_args->{job_entry_pc} ? 'Job Entry PC' : $self->schema->resultset('DirectoryEntry')->find($self->_uid)->display_name;
            my $account = $job->account;
            my $project_name = $job->project_name;
            my $customer = $job->customer_id ? $customers->find($job->customer_id) : undef;
            my $customer_name = $customer ? $customer->get_column('customer_display_name') . ' &lt;' . $customer->get_column('email') . '&gt;' : 'None';
            my $pi = $job->pi_id ? $customers->find($job->pi_id) : undef;
            my $pi_name = $pi ? $pi->get_column('customer_display_name') . ' &lt;' . $pi->get_column('email') . '&gt;' : 'None';
            my $fab_id = defined $job->property_id ? $job->property_id : '';
            my $chartstring = join('', map { "<td>" . ($account ? $account->get_column($_) : '') . "</td>" } (qw/ fund_code deptid program_code project_id chartfield3 chartfield1 chartfield2 descr50 /));
#            my $chartstring = sprintf("%-6s%-8s%-9s%-10s%-9s%-12s%-12s%s", map { $account->get_column($_) } (qw/ fund_code deptid program_code project_id chartfield3 chartfield1 chartfield2 descr50 /));
            sendmail(
                To => 'nick@physics.umn.edu',
                From => 'net@physics.umn.edu',
                'MIME-Version' => '1.0',
                'Content-Type' => 'text/html',
                Subject => 'EFS Chartstring for Your Review - CSE Shop Job #' . $job_id,
                Message => <<EOF,
<table cellpadding="3" cellspacing="1"><tr><td>The EFS Chartstring for Job #$job_id has been updated. Is this EFS Chartstring okay to charge for account code 720403 (labor) and 720299 (materials)?</td></tr></table>
<br/>
<table cellpadding="3" cellspacing="1">
<tr><td align="right">Project Name:</td><td>$project_name</td></tr>
<tr><td align="right">Customer:</td><td>$customer_name</td></tr>
<tr><td align="right">PI:</td><td>$pi_name</td></tr>
<tr><td align="right">FAB ID:</td><td>$fab_id</td></tr>
</table>
<br/>
<table cellpadding="3" cellspacing="1">
<tr><td width="20">FUND</td><td width="25">DEPTID</td><td width="30">PROGRAM</td><td width="50">PROJECT</td><td width="50">EMPLID</td><td width="60">CF1</td><td width="60">CF2</td><td>DESCRIPTION</td></tr>
<tr>$chartstring</tr>
</table>
<br/>
<table cellpadding="3" cellspacing="1"><tr><td><a href="https://www.physics.umn.edu/resources/shopdb/job.html?job_id=$job_id">https://www.physics.umn.edu/resources/shopdb/job.html?job_id=$job_id</a></td></tr></table>
EOF
                %{$mail_params->{efs_update}},
            );
        }

    }
    return $self->item;
}

has_field 'entry_machinist' => (
    label => 'Entry Machinist',
    type => 'Select',
    empty_select => ' -- ',
    build_javascript => sub {
        my $self = shift;
        my $output = "field = \$('" . $self->html_name . "');\n";
        if ($self->required) {
            $output .= "field.validateMethod = function() { return this.value != '' ? true : false; };\n";
            $output .= "field.errorMsg = 'Entry machinst is required.';\n";
            $output .= "field.errorNode = field.parentNode.select('.error_message').first();\n"
                if ($self->has_errors);
        }
        return $output;
    },
    # Allow Job Entry PCs and foreman to change entry_machinist field
    auth => sub {
        my ($auth_args, $job_item) = @_;
        return (!$job_item && $auth_args->{'job_entry_pc'}) || $auth_args->{'foreman'};
    },
    # Allow foreman and machinists to see entry_machinist field
    read_auth => sub { my $auth_args = shift; return $auth_args->{'foreman'} || $auth_args->{'machinist_id'} },
);

sub options_entry_machinist {
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

has_field 'filemaker_job_id' => (
    type => 'Integer',
    label => 'FileMaker Job #',
    auth => [ { auth_args => [ 'machinist_id' ] } ],
    read_auth => [ { auth_args => [ 'machinist_id' ] } ],
);

has_field 'status' => (
    label => 'Job Status',
    label_column => 'label',
    sort_column => 'job_status_id',
    type => 'Select',
    auth => [ { item => [ '!new' ], auth_args => [ 'foreman', 'machinist_id' ] } ],
    read_auth => [ { auth_args => [ 'foreman' ] }, { item => [ '!new' ] } ],
    auth_over_foreman => 1,
    deflate_value_method => sub {
        my ($self, $value) = @_;
        $value ||= $self->value;
        warn "deflating field " . $self->name . " value $value";
        for my $option ($self->options) {
            if ($value eq $option->{value}) {
                return $value;
            }
            if ($value eq $option->{label}) {
                return $option->{value};
            }
        }
        $self->add_error("Invalid status value $value");
        return $value;
    },
);

has_field 'status_comment' => (
    label => 'Status Comment',
    auth => [ { auth_args => [ 'machinist_id' ] } ],
    read_auth => [ { auth_args => [ 'foreman' ] }, { item => [ '!new' ] } ],
);

has_field 'parent_job_id' => (
    label => 'Parent Job',
    type => '+CompleteJob',
    style => 'width:300px;',
    recent => 1,
    auth => [ ], # only foreman
);

sub validate_parent_job_id {
    my ($self, $field) = @_;
    warn "validate_parent_job_id";
    if (!$self->schema->resultset('Jobs')->find({ job_id => $field->value })) {
        $field->add_error('Invalid parent job id');
    }
}

has_field 'project_name' => (
    label => 'Project Name',
    style => 'width:300px;',
    required => 1,
    required_message => 'Project name is required.',
    help_message => 'Provide a descriptive name for your project.',
    build_javascript => sub {
        my $self = shift;
        my $output = "field = \$('" . $self->html_name . "');\n";
        $output .= "field.validateMethod = function() { return this.value != '' ? true : false; };\n";
        $output .= "field.errorMsg = 'Project name is required.';\n";
        $output .= "field.errorNode = field.parentNode.select('.error_message').first();\n"
            if ($self->has_errors);
        return $output;
    },
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'customer', 'pi', 'entry_machinist' ], item => [ '!finalized' ] } ],
);
has_field 'child_jobs' => (
    label => 'Child Jobs',
    type => 'Multiple',
    auth => [ ], # only foreman
);
sub options_child_jobs {
    my $self = shift;
    return unless $self->item;
    my @child_jobs = $self->item->child_jobs;
    my @options;
    for (@child_jobs) {
        push(@options, {
            label => $_->project_name,
            value => $_->job_id,
        });
    }
    return @options;
}
has_field 'customer' => (
    type => '+CompleteCustomer',
    label => 'Customer',
    prefix => 'customer',
    style => 'width:300px;',
    auth => [ { item => [ 'new' ], auth_args => [ 'job_entry_pc', 'machinist_id' ] } ],
    required => 1,
    required_message => 'Customer is required.',
);
has_field 'pi' => (
    type => '+CompleteCustomer',
    label => 'PI',
    prefix => 'pi',
    help_message => 'Enter the name of the Principal Investigator if different from the Customer. As you type, matches will appear in a drop down list. Only people from the University will appear. Click the plus sign to add a new person.',
    style => 'width:300px;',
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'customer', 'machinist_id' ], item => [ '!finalized' ] } ],
);
has_field 'property_id' => (
    label => 'FAB ID',
    help_message => 'If this project involves University Capital Equipment, enter the Asset ID here.',
    style => 'width:300px',
    apply => [ { check => qr/^\d+$/, message => 'Must be all digits - Leave off leading FAB' } ],
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'customer', 'pi', 'machinist_id' ] } ],
);
has_field 'quantity_ordered' => (
    label => 'Order Quantity',
    auth => [ { item => [ 'new' ] }, { item => [ '!approved' ], auth_args => [ 'customer', 'pi', 'machinist_id' ] } ],
    default => 1,
    required => 1,
    help_message => 'Enter the order quantity.',
);
has_field 'bill_address' => (
    type => '+CompleteAddress',
    label => 'Billing Address',
    style => 'width:300px;vertical-align:top;',
    dropdown_ids => [ 'customer_uid', 'pi_uid' ],
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'customer', 'pi', 'machinist_id' ] } ],
);
has_field 'ship_address' => (
    type => '+CompleteAddress',
    label => 'Shipping Address',
    dropdown_ids => [ 'customer_uid', 'pi_uid' ],
    style => 'width:300px;vertical-align:top;',
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'customer', 'pi', 'machinist_id' ] } ],
);
has_field 'account_key' => (
    type => '+CompleteAccount',
    label => 'EFS Account',
    help_message => 'If the project will be billed to a University EFS account, enter the chart string here. Chart string values can be entered in any order. If a match cannot be found, a new account can be added by clicking the plus sign.',
    style => 'width:300px;',
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'customer', 'pi', 'machinist_id' ] } ],
);
has_field 'customer_po_num' => (
    label => 'Customer PO #',
    style => 'width:300px;',
    auth => [ { auth_args => [ 'machinist_id' ] } ],
    read_auth => [ { auth_args => [ 'machinist_id' ] } ],
);
has_field 'customer_ref_1' => (
    label => 'Reference Number 1',
    help_message => 'An optional reference number that can be used for job tracking.',
    style => 'width:300px;',
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'customer', 'pi', 'machinist_id' ] } ],
);
has_field 'customer_ref_2' => (
    label => 'Reference Number 2',
    help_message => 'A second optional reference number that can be used for job tracking.',
    style => 'width:300px;',
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'customer', 'pi', 'machinist_id' ] } ],
);
has_field 'contact_number' => (
    label => 'Contact Phone #',
    style => 'width:300px;',
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'customer', 'pi', 'machinist_id' ] } ],
);
has_field 'instructions' => (
    type => 'TextArea',
    help_message => 'Enter any special instructions for the machinists.',
    style => 'width:300px;height:100px;',
    auth => [ { item => [ 'new', ] }, { auth_args => [ 'customer', 'pi', 'machinist_id' ], item => [ '!approved' ] } ],
);
has_field 'justification' => (
    label => 'EFS Account and Justification',
    type => 'TextArea',
    help_message => 'Enter EFS account fields and the accounting justification. An accounting justification is required for any jobs billed to University EFS accounts.',
    style => 'width:300px;height:100px;',
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'customer', 'pi', 'machinist_id' ], item => [ '!approved' ] } ],
);
has_field 'projected_charge_hours' => (
    label => 'Projected Charge Hours',
    style => 'width:150px;',
    auth => [ ],
    read_auth => [ ],
);
has_field 'projected_labor_cost' => (
    type => '+Currency',
    label => 'Projected Labor Cost',
    style => 'width:150px;',
    auth => [ ],
    read_auth => [ ],
);
has_field 'projected_material_cost' => (
    type => '+Currency',
    label => 'Projected Material Cost',
    style => 'width:150px;',
    auth => [ ],
    read_auth => [ ],
);
has_field 'in_date' => (
    type => '+Date',
    label => 'In Date',
    auth => [ { auth_args => [ 'foreman' ], item => [ 'new' ] }, { auth_args => [ 'foreman' ], item => [ '!new' ], item => [ '!in_date' ] } ],
    read_auth => [ { item => [ '!new' ], item => [ 'finalized' ] } ],
    auth_over_foreman => 1,
);
sub default_in_date {
    my $self = shift;
    return $self->today;
}
has_field 'approved_date' => (
    type => '+Date',
    label => 'Approved Date',
    auth => [ { item => [ '!approved' ], auth_args => [ 'foreman' ] } ],
    read_auth => [ { item => [ '!new' ], item => [ 'finalized' ] } ],
    auth_over_foreman => 1,
);
has_field 'need_date' => (
    type => '+Date',
    label => 'Need Date',
    help_message => 'Enter the date by which the project needs to be completed and/or delivered.',
    build_javascript => sub {
        my $self = shift;
        my $output = "field = \$('" . $self->html_name . "');\n";
        $output .= "field.validateMethod = function(button) { return (button !== null && button.value.indexOf('Production') != -1 && this.value == '') ? false : true; };\n";
        $output .= "field.errorMsg = 'Need date is required for Production.';\n";
        $output .= "field.errorNode = field.parentNode.select('.error_message').first();\n"
            if ($self->has_errors);
        return $output;
    },
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'customer', 'pi', 'machinist_id' ], item => [ '!finalized' ] } ],
);
has_field 'finish_date' => (
    type => '+Date',
    label => 'Finish Date',
    auth => [ { auth_args => [ 'machinists' ] } ],
    read_auth => [ { auth_args => [ 'machinist_id' ] } ],
);
has_field 'ship_date' => (
    type => '+Date',
    label => 'Ship Date',
    auth => 0,
    read_auth => [ { auth_args => [ 'machinist_id' ] } ],
);
has_field 'quantity_shipped' => (
    label => 'Quantity Shipped',
    auth => 0,
    read_auth => [ { item => [ 'finalized' ], auth_args => [ 'machinist_id', 'foreman' ] } ],
    auth_over_foreman => 1,
);
has_field 'machinists' => (
    type => 'Multiple',
    build_javascript => sub {
        my $self = shift;
        my $output = "field = \$('" . $self->html_name . "');\n";
        $output .= "field.validateMethod = function(button) { return (button !== null && button.value.indexOf('Approve for Production') != -1 && this.selectedIndex == -1) ? false : true; };\n";
        $output .= "field.errorMsg = 'At least one Machinist is required for Production.';\n";
        $output .= "field.errorNode = field.parentNode.select('.error_message').first();\n"
            if ($self->has_errors);
        return $output;
    },
    size => 12,
    auth => [ { auth_args => [ 'machinist' ] } ],
    read_auth => [ { auth_args => [ 'machinist_id' ] } ],
    options_method => sub { shift->form->field('entry_machinist')->options },
);
sub options_machinists_disabled {
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

has_field 'external' => (
    type => 'Checkbox',
    label => 'External',
    auth => [ { auth_args => [ 'machinist_id' ] } ],
    read_auth => [ { auth_args => [ 'machinist_id' ] } ],
);
has_field 'attachments' => (
    type => '+FileManager',
    label => 'Attached Files',
    auth => [ { item => [ '!new' ], auth_args => [ 'foreman', 'customer', 'pi', 'machinist_id' ] } ],
    auth_over_foreman => 1,
);
has_field 'job_update' => (
    type => 'Submit',
    value => 'Update',
    auth => [ { auth_args => [ 'foreman', 'machinist_id', 'customer', 'pi' ], item => [ '!new' ] } ],
    widget_wrapper => 'None',
    auth_over_foreman => 1,
);
has_field 'job_draft' => (
    type => 'Submit',
    value => 'Save as Draft',
    auth => [ { item => [ 'new' ] } ],
    widget_wrapper => 'None',
    auth_over_foreman => 1,
);
has_field 'job_finalize' => (
    type => 'Submit',
    value => 'Submit for Production',
    auth => [ { item => [ 'new' ], auth_args => [ '!foreman' ] }, { auth_args => [ 'customer', 'pi', 'machinist_id' ], item => [ '!finalized' ] } ],
    widget_wrapper => 'None',
    auth_over_foreman => 1,
);
has_field 'job_approve' => (
    type => 'Submit',
    value => 'Approve for Production',
    auth => [ { item => [ 'new', '!approved' ], auth_args => [ 'foreman' ] } ],
    widget_wrapper => 'None',
    auth_over_foreman => 1,
);
has_field 'modified_date' => (
    widget => 'NoRender',
    auth => 1,
);

sub render {
    my ($self, $args) = @_;
    $args ||= ();
    my @hidden_fields = ( 'modified_date', 'child_jobs' );
    # Button fields
    my @button_fields = grep { $_->type eq 'Submit' } $self->sorted_fields;
    # Filter out hidden, button, and no-auth fields
    my @visible_fields = grep { my $field = $_; ($field->has_read_auth || $field->has_auth) && ! grep { $field->name eq $_ } ( @hidden_fields, map { $_->name } @button_fields ); } $self->sorted_fields;
    # List of field name globs to include in second column (none if not machine shop person)
    my @second_column_field_globs = ($self->auth_args->{foreman} || $self->_machinist_id) ?
        ( qw/filemaker entry status external date shipped machinists projected attachments/ )
        : ( );
    # List of authed fields not found in @second_column_field_globs
    my @first_column_fields = grep { my $field = $_; ! grep { $field->name =~ /\Q$_\E/ } @second_column_field_globs } @visible_fields;
    # Only use @second_column_fields for which user has auth
    my @second_column_fields = grep { my $field = $_; ! grep { $field->name eq $_->name } @first_column_fields } @visible_fields;
    my $output = '';
    if (!exists($args->{'wrapper'})) {
        $output .= '<form id="shopdb-job-edit-form" method="post"><table id="job_form_' . $self->name . '">';
    }
    $output .= '<tr><td valign="top"><table width="100%" cellpadding="3" cellspacing="0">';
    for my $field (@first_column_fields) {
        $output .= $field->render;
    }
    if (@second_column_fields) {
        $output .= '</table></td><td valign="top"><table width="100%" cellpadding="3" cellspacing="0">';
        for my $field (@second_column_fields) {
            $output .= $field->render;
        }
    }
    $output .= '</table></td></tr><tr style="height: 50px"><td colspan="2" align="right">';
    $output .= $_->render for (@button_fields);
    $output .= '</td></tr>';
    if (!exists($args->{'wrapper'})) {
        $output .= '</table></form>';
    }
    return $output;
}

__PACKAGE__->meta->make_immutable();

1;
