package Tablesearch::Output::HTML;

use strict;
use warnings;

sub new {
    my ($class, $ts) = @_;

    bless { ts => $ts }, $class;
}

sub name {
    return 'HTML';
}

sub _h {
    my $m = HTML::Mason::Request->instance;
    return $m->interp->apply_escapes($_[0], 'h');
}

sub _u {
    my $m = HTML::Mason::Request->instance;
    return $m->interp->apply_escapes($_[0], 'u');
}

sub begin {
    my $self = shift;
    my %args = @_;
    my $ts = $self->{ts};

    my $m = HTML::Mason::Request->instance;
    my $r = $m->apache_req;

    print "\n<!-- begin tablesearch -->\n";

    print '<form name="' . $ts->{prefix} . 'tsform" method="get" action="' . _h($r->uri) . '">' . "\n" unless ($ts->{no_form});

    if ($ts->{debug}) {
        use Data::Dumper;
        my ($sql, @exec_args) = $ts->sql;
        print "<font color='red'>DEBUG (sql): " . $sql . ' // ARGS: ' . Dumper(\@exec_args) . "</font><br>";
    }
}

sub end {
    my $self = shift;
    my %args = @_;

    my $ts = $self->{ts};
    my $data = $args{data};
    my $html = $args{html};

    my $m = HTML::Mason::Request->instance;

    use List::Util qw[min max];
    use JSON;
    use magicpaginator;

    my ($rows) = $data->found_rows;
    my $pages = ($ts->{no_limit} ? 1 : ($rows % $ts->{limit}) > 0 ? (int($rows/$ts->{limit}) + 1) : ($rows/$ts->{limit}));

    if (!$ts->{hide_header}) {
        print "\n<!-- begin tablesearch header -->\n";
        print '<table width="100%" class="tablesearch-header">';
        if($ts->{filter} || !$ts->{hide_search} || $ts->{excel_link}) {
            print '<tr>';
            if ($ts->{filter} || !$ts->{hide_search}) {
                print '<td nowrap="1" colspan="' . ($ts->{excel_link} ? '2' : '3') . '">';

                if ($ts->{filter}) {
                    print '<select name="' . $ts->{prefix} . 'filter" onchange="document.' . $ts->{prefix} . 'tsform.submit();"><option value="all">------ No filter ------</option>' . "\n";

                    my @distinct_filter_values = $data->distinct_filter_values;

                    foreach my $field (@distinct_filter_values) {
                        my ($field_value, $field_name) = @$field;
                        print "<option value=\""._h($field_value)."\" ".($ts->{filter} eq $field_value ? 'selected="1"' : "").">"._h($field_name)."</option>\n";
                    }

                    if(defined($ts->{filter_groups})) { #TODO: ARGS?
                        print "<optgroup label=\"Filter Groups\">\n";
                        foreach my $filter_group (keys %{$ts->{filter_groups}}) {
                            print "<option value=\"$filter_group\" ".($filter_group eq $ts->{filter} ? 'selected="1"' : "").">$ts->{filter_groups}->{$filter_group}->{'display_name'}</option>\n";
                        }
                    }
                    print "</select>";
                }

                if(!$ts->{hide_search}) {
                    print ' <input type="text" size="30" name="' . $ts->{prefix} . 'search" title="Prefix terms with + for exact match" value="' . _h($ts->{search}) . '" onchange="document.' . $ts->{prefix} . 'tsform.submit();" />';
                    print ' <input type="submit" value="Search" />';
                }

                print "</td>";
            }
            if ($ts->{excel_link}) {
                print '<td nowrap="1" colspan="' . (($ts->{filter} || !$ts->{hide_search}) ? '1' : '3') . '" align="right" style="padding-right: 3px;">'
                    . '<a href="' . _h($m->scomp('/mason/makeurl.comp', nargs => { %{$m->request_args}, $ts->{prefix} . 'excel' => 1 })) . '"><img border="0" src="/images/excel.png" style="margin-bottom: -5px;">&nbsp;Export to Excel</a></td>';
            }
            print "</tr>\n";
        }

        if ($ts->{show_column_filter}) {
            my $prefix = $ts->{prefix} || '';
            my @selected = $ts->column_names;
            my @available = grep { my $col = $_; ! grep { $col eq $_ } (@selected, 'TS_RNUM') } @{$ts->raw_column_names};
            print '<tr><td colspan="3"><table>';
            print "<tr><td>Selected fields</td><td></td><td>Available fields</td><td></td></tr>";
            print "<tr>";
            print '<td><select id="' . $prefix . 'selectedCols" multiple="1" name="' . $prefix . 'selectedCols">';
            for my $column (@selected) {
                my $colname = $ts->format_field_name($column);
                print '<option value="' . $column . '">' . $colname . "</option>\n";
            }
            print "</select></td>\n";
            print '<td valign="middle"><input id="' . $prefix . 'addCol" type="button" name="add" value="&lt;&lt;"/><br/><input id="' . $prefix . 'removeCol" type="button" name="remove" value="&gt;&gt;"/></td>';
            print '<td><select id="' . $prefix . 'availableCols" multiple="1">';
            for my $column (@available) {
                my $colname = $ts->format_field_name($column);
                print '<option value="' . $column . '">' . $colname . "</option>\n";
            }
            print "</select>";
            print <<END;
</td><td><input id="${prefix}showAllFields" type="submit" name="${prefix}show_remaining_columns" value="Show All Fields"/></td></tr></table>
<script type="text/javascript">
function moveSelectedCols(from, to) {
    from = \$(from);
    to = \$(to);
    if (from == null || to == null)
        return;
    \$A(from.options).each(function (option, index) { if (option.selected) { from.remove(index); to.add(option); } });
    return;
}
\$('${prefix}addCol').observe('click', function (e) { moveSelectedCols('${prefix}availableCols', '${prefix}selectedCols'); });
\$('${prefix}removeCol').observe('click', function (e) { moveSelectedCols('${prefix}selectedCols', '${prefix}availableCols'); });
\$('${prefix}showAllFields').observe('click', function (e) { document.${prefix}tsform.onsubmit = document.${prefix}tsform.origsubmit; });
</script></td></tr>
END
        }

        if(!$ts->{hide_pagenator}) {
            my $first_disable = ($ts->{no_limit} || $ts->{start} == 0) ? 'disabled="1"' : "";
            my $prev_disable = ($ts->{no_limit} || $ts->{start} == 0) ? 'disabled="1"' : "";
            my $prev_start = $ts->{start} - $ts->{limit} > 0 ? $ts->{start} - $ts->{limit} : 0;

            my $onclick = 'onclick="document.' . $ts->{prefix} . 'tsform.submitButton=this"';

            print '<tr><td style="width: 35%;" nowrap="1">';
            print '<button ' . $onclick . ' type="submit" ' . $first_disable . ' name="' . $ts->{prefix} . 'start" value="0">&lt;&lt;</button>&nbsp;';
            print '<button ' . $onclick . ' type="submit" ' . $prev_disable . ' name="' . $ts->{prefix} . 'start" value="' . $prev_start . '">Prev</button>';
            print ' Page <select name="' . $ts->{prefix} . 'page" onchange="document.' . $ts->{prefix} . 'tsform.submit();">';
            print '<option value="0">-</option>';
            my $cur_page = int($ts->{start}/$ts->{limit}) + 1;
            my $paginator = new magicpaginator(cur_page => $cur_page, pages => $pages, padding => 20, approx_entries => 40);
            foreach my $page ($paginator->get_pages) {
                print '<option value="' . ($cur_page == $page ? '0" selected="1"' : $page.'"') . '>' . $page .'</option>';
            }
            print '</select>';
            print ' of ' . $pages . ' ';

            my $next_disable = ($ts->{no_limit} || $ts->{start} >= $rows - $ts->{limit}) ? 'disabled="1"' : "";
            my $next_start = $ts->{start} + $ts->{limit} < $rows ? $ts->{start} + $ts->{limit} : $ts->{start};
            my $last_disable = ($ts->{no_limit} || $ts->{start} >= $rows - $ts->{limit}) ? 'disabled="1"' : "";
            my $last_start = ($pages-1)*$ts->{limit};

            my $first_row = $rows == 0 ? 0 : $ts->{no_limit} ? 1 : $ts->{start} + 1;
            my $last_row = $ts->{no_limit} ? $rows : min($ts->{start}+$ts->{limit}, $rows);

            print '<button ' . $onclick . ' type="submit" ' . $next_disable . ' name="' . $ts->{prefix} . 'start" value="' . $next_start . '">Next</button>&nbsp;';
            print '<button ' . $onclick . ' type="submit" ' . $last_disable . ' name="' . $ts->{prefix} . 'start" value="' . $last_start . '">&gt;&gt;</button>&nbsp;';
            print '<button ' . $onclick . ' type="submit" name="' . $ts->{prefix} . 'show_all" value="' . ($ts->{no_limit} ? '0' : '1') . '">' . ($ts->{no_limit} ? 'Paginate' : 'Show All') . '</button>';
            print '</td>';
            print '<td nowrap="1" style="width: 30%; padding-left: 5px; padding-right: 5px" align="center">Showing results <b>' . $first_row . ' - ' . $last_row . '</b> of ' . $rows;
            print ((defined($m->request_args->{'where'}) && rindex($ts->{where},$m->request_args->{'where'}) > -1 && !$ts->{hide_search}) ? " Default filter applied." : "" );
            print '</td>';
            print '<td nowrap="1" style="width: 35%" align="right">';
            print 'Results per page <input type="text" size="3" name="' . $ts->{prefix} . 'limit" value="' . $ts->{limit} . '" onchange="document.' . $ts->{prefix} . 'tsform.submit();" />'
                if (!$ts->{no_limit});
            print ' <input ' . $onclick . ' type="submit" name="refresh" value="Refresh" />';
            print '</td></tr>';
        }
        print '</table>';
        print "<!-- end tablesearch header -->\n";
    } # END !$ts->{hide_header}

    unless ($ts->{no_form}) {

        if (!$ts->{pathquery}) {
            print '<input type="hidden" name="' . $ts->{prefix} . 'sort" value="' . $ts->{sort} . '" />';
            print '<input type="hidden" name="' . $ts->{prefix} . 'sort_reverse" value="' . (defined $ts->{sort_reverse} ? $ts->{sort_reverse} : '') . '" />';
        }

        foreach my $arg ($self->get_extra_url_args) {
            print '<input type="hidden" name="' . $arg->{arg} . '" value="' . _h($arg->{val}) . '" />';
        }

        print "\n</form>\n";
    }

    print "<!-- begin tablesearch data -->\n";
    if ($ts->{data_wrapper_form}) {
        print '<form autocomplete="off">';
    }
    print '<table cellspacing="0" cellpadding="5" width="100%"' . ($ts->{html_table_id} ? ' id="'.$ts->{html_table_id}.'"' : '') . ">\n";
    if (defined($ts->{data_wrapper})) {
        die "data_wrapper must be a sub" unless ref($ts->{data_wrapper}) eq 'CODE';
        $html = $ts->{data_wrapper}->($html, $ts);
    }
    print $html;
    print "\n</table>\n<!-- end tablsearch data -->\n";
    if (defined($ts->{ajax_url})) {
        my $formname = $ts->{prefix} . 'tsform';
        print '
<script type="text/javascript">
    form = document.' . $formname . ';
    form.action = "' . $ts->{ajax_url} . '";
    form.submit = function(href) {
        if (this.requestPending) { return false; }
        this.requestPending = true;
        this.grayBox = new Element("div").setStyle({ opacity: 0.5, position: "absolute", backgroundColor: "#CCC" }).clonePosition(this.parentNode, { setLeft: false, setTop: false });
        this.parentNode.insertBefore(this.grayBox, this);
        params = ' . to_json($ts->{ajax_parameters} || {}) . ';
        if (this.submitButton != null) {
            params[this.submitButton.name] = this.submitButton.value;
        }' . ($ts->{sort} ? '
        params["' . $ts->{prefix} . 'sort"] = "' . $ts->{sort} . '"' : '') . '
        if (typeof(href) == "string") {
            params = Object.extend(params, href.toQueryParams());
        }
        if ($("' . $ts->{prefix} . 'selectedCols") != null) {
            selectedCols = { ' . $ts->{prefix} . 'columns: $A($("' . $ts->{prefix} . 'selectedCols").options).collect(function (option) { return option.value }) };
            params = Object.extend(params, selectedCols);
        }
        ' . ($ts->{ajax_pre_callback} || '') . '
        this.request({
            parameters: params,
            onSuccess: function(response) {
                this.requestPending = false;
                this.parentNode.update(response.transport.responseText);
                ' . ($ts->{ajax_post_callback} || '') . '
            }.bind(this),
            onFailure: function(response) {
                this.requestPending = false;
                this.grayBox.remove();
                res = response.transport.responseText;
                if (res.unfilterJSON().isJSON())
                    err = res.evalJSON().err;
                else
                    err = res;
                alert("There was an problem processing your request: " + err);
            }.bind(this)
        });
        return false;
    }.bind(form);
    form.onsubmit = form.submit;
</script>
';
    }
    elsif ($ts->{show_column_filter}) {
        print '
<script type="text/javascript">
    form = document.' . $ts->{prefix} . 'tsform;
    form.origsubmit = form.submit;
    form.submit = function(href) {
        if ($("' . $ts->{prefix} . 'selectedCols") != null) {
            selectedCols = $A($("' . $ts->{prefix} . 'selectedCols").options);
            selectedCols.each(function (option) {
                form.appendChild(new Element("input", { type: "hidden", name: "' . $ts->{prefix} . 'columns", value: option.value }));
            });
        }
        form.origsubmit();
    }
    form.onsubmit = form.submit;
</script>
';
    }
    if ($ts->{data_wrapper_form}) {
        print '</form>';
    }
    print "\n<!-- end tablesearch -->\n";
}

sub start_header {
    my $self = shift;
    my %args = @_;

    my $ts = $self->{ts};

    $ts->{tmp}->{html} .= "<tr class=\"tablehead\">";
}

sub header {
    my $self = shift;
    my %args = @_;

    my $ts = $self->{ts};
    my $column_width = $args{params}{width} || undef;

    $ts->{tmp}->{html} .= "<th" . (($ts->{no_header_wrap} || $args{params}{no_header_wrap}) ? ' nowrap' : '') . " class=\"tableheader\"" . ($column_width ? " style=\"min-width: ${column_width}px;\"" : "") . ">";
    if ($ts->{no_sort} || $args{params}{no_sort}) {
        $ts->{tmp}->{html} .= $args{name};
    } else {
        $ts->{tmp}->{html} .= $self->_sortlink(
            pathquery    => $ts->{pathquery},
            prefix       => $ts->{prefix},
            sort         => $ts->{sort},
            sort_reverse => $ts->{sort_reverse},
            name         => $args{name},
            sortname     => $args{sortname},
            ts           => $ts,
        );
    }
    $ts->{tmp}->{html} .= "</th>";
}

sub end_header {
    my $self = shift;
    my %args = @_;

    my $ts = $self->{ts};

    $ts->{tmp}->{html} .= "</tr>\n";
}

sub start_row {
    my $self = shift;
    my %args = @_;

    my $ts = $self->{ts};
    my $row = $args{row};

    if (!defined($ts->{tmp}->{oddeven})) { $ts->{tmp}->{oddeven} = 'even'; }

    $ts->{tmp}->{oddeven} = $ts->{tmp}->{oddeven} eq 'odd' ? 'even' : 'odd';

    if (defined($ts->{prerow})) {
        die "prerow must be a sub" unless ref($ts->{prerow}) eq 'CODE';
        $ts->{tmp}->{html} .= $ts->{prerow}->($row, $ts);
    }

    return if ($ts->{tmp}->{skiprow});

    $ts->{tmp}->{html} .= '<tr class="' . $ts->{tmp}->{oddeven} . '"'
        . ($ts->{row_tagger} ? ' ' . $ts->{row_tagger}->($row) : '') . '>';
}

sub row_data {
    my $self = shift;
    my %args = @_;

    my $ts = $self->{ts};
    my $field_param = $args{field_param};
    my $data_format = $args{data_format};
    my $value = $args{value};
    my %row = %{$args{row}};
    my $i = $args{i};
    my $incr = $args{incr};

    my ($id, $class);
    my $extra_attrs = '';

    my $eval = sub {
        my $in = shift;
        if (defined($in)) {
            $in =~ s/(\$row\{\w+\}|\$id|\$incr)/$1/gee;
        }
        return $in;
    };

    # Allow column to be conditionally skipped (allows for other columns to have colspan > 1)
    if (defined $field_param->{skip_td} && ref $field_param->{skip_td} eq 'CODE') {
        return if ($field_param->{skip_td}->($value, $field_param->{skip_td}, \%row, $ts));
    }

    $id = $eval->($field_param->{'html_id'});
    $class = $eval->($field_param->{'html_class'});

    if (defined $field_param->{'extra_td_attrs'}) {
        my %extra_td_attrs;
        if (ref $field_param->{'extra_td_attrs'} eq 'CODE') {
            %extra_td_attrs = %{ $field_param->{'extra_td_attrs'}->($value, $field_param->{'extra_td_attrs'}, \%row, $ts) || {} };
        }
        else {
            %extra_td_attrs = %{ $field_param->{'extra_td_attrs'} };
        }
        $extra_attrs = ' ' . join(' ', map { $_ . '="' . _h($eval->($extra_td_attrs{$_})) . '"' } keys %extra_td_attrs);
    }

    $ts->{tmp}->{html} .= '<td' . (defined($id) ? ' id="' . _h($id) . '"' : '') .
                            ' class="tableitem' . (defined($class) ? ' ' . _h($class) : '') . '"' .
                            $extra_attrs .  ($field_param->{'nowrap'} ? " nowrap>" : ">");

    $ts->{tmp}->{html} .= defined $value ? $value : '';

    $ts->{tmp}->{html} .= "</td>";

    # Moving this inside the td can make autocompleter stuff really slow in students area...
    # (putting it outside the td makes it process it all at the end? Or does it reference the td... hrmm.)
    $ts->{tmp}->{html} .= $eval->($field_param->{'html_append'})
        if (defined($field_param->{'html_append'}));
}

sub end_row {
    my $self = shift;
    my %args = @_;

    my $ts = $self->{ts};
    my $row = $args{row};

    $ts->{tmp}->{html} .= "</tr>\n";

    if (defined($ts->{postrow})) {
        die "postrow must be a sub" unless ref($ts->{postrow}) eq 'CODE';
        $ts->{tmp}->{html} .= $ts->{postrow}->($row, $ts);
    }
}

sub get_extra_url_args {
    my $self = shift;
    my $ts = $self->{ts};
    my @vals;
    my $m = HTML::Mason::Request->instance;
    foreach my $arg (@{$ts->{extra_url_args} || []}) {
        my $val = $m->request_args->{$arg};
        if (ref $val) {
            push @vals, { arg => $arg, val => defined $_ ? $_ : '' } for (@$val);
        }
        else {
            push @vals, { arg => $arg, val => defined $val ? $val : '' };
        }
    }
    return @vals;
}

sub _sortlink {
    my $self = shift;
    my %args = @_;

    my $prefix = $args{prefix};
    my $name = $args{name};
    my $sortname = $args{sortname};
    my $sort = $args{sort};
    my $sort_reverse = 0;
    my $ts = $args{ts};
    my $pathquery = $args{pathquery};

    # XXX remove
    my $m = HTML::Mason::Request->instance;

    my %rargs = $m->request_args;
    my $search = $rargs{"${prefix}search"};
    my $filter = $rargs{"${prefix}filter"};
    my $limit = $rargs{"${prefix}limit"};
    my $show_all = $rargs{"${prefix}show_all"};
    my $show_remaining_columns = $rargs{"${prefix}show_remaining_columns"};
    my $sort_img = '';
    my $extra_args_url = '';
    if($sortname eq $sort) {
      $sort_reverse = $args{sort_reverse} ? 0 : 1;
      $sort_img = '&nbsp;<img alt="' . ($sort_reverse ? 'Asc' : 'Desc') . '" src="/images/' . ($sort_reverse ? "s_asc.png" : "s_desc.png") . '" border="0" />';
    }
    if (defined $ts->{extra_url_args}) {
      $extra_args_url = "&" . join("&", map { $_->{arg} . "=" . _u($_->{val}) } $self->get_extra_url_args);
    }

    my $url;
    my $onclick = '';
    my %uargs = ();
    $uargs{"${prefix}sort"} = $sortname if (defined($sortname));
    $uargs{"${prefix}sort_reverse"} = $sort_reverse if (defined($sort_reverse));
    $uargs{"${prefix}search"} = $search if (defined($search));
    $uargs{"${prefix}filter"} = $filter if (defined($filter));
    $uargs{"${prefix}limit"} = $limit if (defined($limit));
    $uargs{"${prefix}show_all"} = $show_all if (defined($show_all));
    $uargs{"${prefix}show_remaining_columns"} = $show_remaining_columns if (defined($show_remaining_columns));

    # ?sort=$sortname&amp;${prefix}sort_reverse=$sort_reverse&${prefix}search=$search&${prefix}filter=$filter${extra_args_url}
    $url = $m->scomp('/mason/makeurl.comp', ($pathquery ? 'pathquery' : 'nargs') => \%uargs);
    $url .= $extra_args_url;
    $url = _h($url);

    if ($ts->{ajax_url}) {
        $onclick = 'onclick="return document.' . $ts->{prefix} . 'tsform.onsubmit(this.href)"';
    }

    return "<a $onclick href=\"$url\" title=\"$sortname\">$name${sort_img}</a>";
}

1;
