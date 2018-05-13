package Tablesearch::Data::DBIC;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = { @_ };
    #use Data::Dumper;
    #print Dumper($self);

    bless($self, $class);
}

sub execute {
    my ($self) = @_;

    $self->sql;

    return 1;
}

sub next {
    my ($self) = @_;
    my $next = $self->{tmp}->{rs}->next();

    if ($next) {
        my %vals = $next->get_inflated_columns();
        return \%vals;
    }

    return undef;
}

sub column_names {
    my ($self) = @_;

    # They don't seem to have public api for us to get this for a resultset. Great.
    return $self->{tablesearch}->{resultset}->_resolved_attrs->{as};
}

sub distinct_filter_values {
    my ($self) = @_;
    my $ts = $self->{tablesearch};
    my $rs = $self->{data};
    $ts->{filter_name_field} = $ts->{filter_field} unless (defined $ts->{filter_name_field});
    # Use relationship values if relationship exists
    if ($rs->result_source->has_relationship($ts->{filter_field})) {
        my $f_class = $rs->result_source->related_class($ts->{filter_field});
        my $source = $rs->result_source->schema->source($f_class);
        my @rows = $rs->result_source->schema->resultset($source->source_name)->search->all;
        my @values = map { [ $_->id, $_->get_column($ts->{filter_name_field}) ] } @rows;
        return @values;
    }
    # Otherwise find distinct values of filter field
    my $distinct_values_rs = $rs->as_subselect_rs->search(undef, { distinct => 1, columns => [ $ts->{filter_field}, $ts->{filter_name_field} ] });
    # Attempt to replace filter_field and filter_name_field values with alias names for use with get_column
    my $as_filter_field = $ts->{filter_field};
    my $as_filter_name_field = $ts->{filter_name_field};
    for (my $i = 0; $i < @{$distinct_values_rs->_resolved_attrs->{select}}; $i++) {
        if ($distinct_values_rs->_resolved_attrs->{select}[$i] eq $as_filter_field) {
            $as_filter_field = $distinct_values_rs->_resolved_attrs->{as}[$i];
        }
        if ($distinct_values_rs->_resolved_attrs->{select}[$i] eq $as_filter_name_field) {
            $as_filter_name_field = $distinct_values_rs->_resolved_attrs->{as}[$i];
        }
    }
    my @distinct_values = $distinct_values_rs->all;
    my @values = map { [ $_->get_column($as_filter_field), $_->get_column($as_filter_name_field) ] } @distinct_values;
    return @values;
}

sub found_rows {
    my ($self) = @_;
    return ($self->{no_limit} || $self->{tablesearch}->{no_limit}) ? $self->{tmp}->{rs}->count : $self->{tmp}->{rs}->pager->total_entries();
}

sub _resultset_to_sql
{
    # a bit hacky, but what is there to do?

    my ($self, $rs) = @_;
    my ($sql, @exec_args_tmp);

    $sql = $rs->as_query();
    ($sql, @exec_args_tmp) = @$$sql;
    $sql =~ s/^\(//;
    $sql =~ s/\)$//;
    # They give us args like [ ['name', val], ['name2', val2] ]...
    my @exec_args = map { $_->[1] } @exec_args_tmp;

    return ($sql, @exec_args);
}

sub sql {
    my $self = shift;
    if ($self->{tmp}) {
        # Query has been executed
        return $self->_resultset_to_sql($self->{tmp}->{rs});
    }
    else {
        my $ts = $self->{tablesearch};
        my $rs = $self->{data};

        if ($ts->{sort} || $ts->{sort_prefix_field}) {
            my @order_clauses;
            if ($ts->{sort_prefix_field}) {
                if ($ts->{sort_prefix_dir}) {
                    push @order_clauses, { -lc($ts->{sort_prefix_dir}) => $ts->{sort_prefix_field} };
                }
                else {
                    push @order_clauses, $ts->{sort_prefix_field};
                }
            }
            if ($ts->{sort}) {
                my @order_fields = @{$rs->_resolved_attrs->{as}};
                my @select_clauses = @{$rs->_resolved_attrs->{select}};
                for (my $i = 0; $i < @order_fields; $i++) {
                    if ($order_fields[$i] eq $ts->{sort}) {
                        my $sort = $select_clauses[$i];
                        # Remove aliases from literal SQL column definitions
                        if (ref $sort) {
                            (my $tmp = $$sort) =~ s/ as .*//i;
                            $sort = \$tmp;
                        }
                        push @order_clauses, { -lc($ts->{sort_order}) => $sort };
                        last;
                    }
                }
                if ($ts->{field_params}->{$ts->{sort}}->{secondary_sort_field}) {
                    push @order_clauses, $ts->{field_params}->{$ts->{sort}}->{secondary_sort_field};
                }
            }
            $rs = $rs->search({}, {
                order_by => [ @order_clauses ],
            });
        }
        else {
            my $sql_maker = $rs->result_source->storage->sql_maker;
            local $sql_maker->{quote_char};
            if (my @order_clauses = $sql_maker->_order_by_chunks($rs->{attrs}{order_by})) {
                my $order_clause = ref $order_clauses[0] ? $order_clauses[0] : [ $order_clauses[0] ];
                if ($order_clause->[0] =~ /^(\w+)(?:\s+(ASC|DESC)\s*)?$/i) {
                    $ts->{sort} = $1;
                    if ($2) {
                        $ts->{sort_order} = uc($2);
                        $ts->{sort_reverse} = ($ts->{sort_order} eq 'ASC' ? 0 : 1);
                    }
                }
            }
        }

        if ($ts->{limit} && !$ts->{no_limit} && !$self->{no_limit}) {
            $rs = $rs->search({}, {
                rows => $ts->{limit},
            });
            $rs = $rs->search({}, {
                page => $ts->{page} || int($ts->{start} / $ts->{limit}) + 1,
            });
        }

        if ($ts->{search}) {
            my @search_terms = split(/\s+/, $ts->{search});
            my @search_fields = @{ $ts->{search_fields} || [] };
            my @excluded_search_fields = @{ $ts->{excluded_search_fields} || [] };
            my @rs_fields = @{$rs->_resolved_attrs->{select}};
            my @rs_as = @{ $rs->_resolved_attrs->{as}};
            $rs = $rs->search([ -and => [ map {
                my @search;
                for my $field_num (0..$#rs_fields) {
                    my $field = $rs_fields[$field_num];
                    if (ref($field)) {
                        # Field is raw sql rather than a column. We need to get the part before the AS.
                        # ex. DATEDIFF(me.need_date, NOW()) AS days_left
                        (my $field_name = $$field) =~ s/ as .*//i;
                        # Bizarre literal SQL hack
                        # See http://kobesearch.cpan.org/htdocs/SQL-Abstract/SQL/Abstract.pm.html#Literal_SQL_with_placeholders_and_bi
                        push (@search, ($_ =~ /^\+(.*)/) ?
                                \[ "$field_name = ?" => [ dummy => $1 ] ] :
                                \[ "$field_name LIKE ?" => [ dummy => "%$_%" ] ]
                        ) unless (
                            (grep { $_ =~ /^($field_name|$rs_as[$field_num])$/ } @excluded_search_fields) ||
                            (@search_fields && ! grep { $_ =~ /^($field_name|$rs_as[$field_num])$/ } @search_fields)
                        );
                    }
                    else {
                        push (@search, ($_ =~ /^\+(.*)/) ?
                                ($field => $1) :
                                ($field => { -like => "%$_%" })
                        ) unless (
                            (grep { $_ =~ /^($field|$rs_as[$field_num])$/ } @excluded_search_fields) ||
                            (@search_fields && ! grep { $_ =~ /^($field|$rs_as[$field_num])$/ } @search_fields)
                        );
                    }
                }
                [ @search ];
            } @search_terms ] ]);
        }

        if ($ts->{filter} && $ts->{filter} ne 'all') {
            # Use relationship info if filter_field is a relationship and filter_search_name isn't set
            if (! defined $ts->{filter_search_name} && $rs->result_source->has_relationship($ts->{filter_field})) {
                my @fk_columns = keys %{ $rs->result_source->relationship_info($ts->{filter_field})->{attrs}->{fk_columns} } ;
                warn "Found more than one column in join condition for relationship $ts->{filter_field}"
                    if (@fk_columns != 2);
                $ts->{filter_search_name} = 'me.' . $fk_columns[0];
            }
            $rs = $rs->search({ ($ts->{filter_search_name} || $ts->{filter_field}) => $ts->{filter} });
        }

        $self->{tmp}->{rs} = $rs;

        return $self->_resultset_to_sql($rs);
    }
}

1;
