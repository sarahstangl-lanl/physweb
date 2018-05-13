package Tablesearch::Data::DBI;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;

    my $self = bless(\%args, $class);

    my $ts = $self->{'tablesearch'};

    # Import DBD::AnyData data
    if (defined($ts->{data})) {
        if(!defined($ts->{table})) {
            $ts->{table} = 'data';
        }
        $ts->{no_calc_found_rows} = 1;
        $ts->{quote_char} = '';
        # Use a copy of data (DBD::AnyData modifies the original data)
        my @data = @{$ts->{data}};
        my @copy = @data;
        $self->_dbh->func($ts->{table}, 'ad_clear');
        $self->_dbh->func($ts->{table}, 'ARRAY', \@copy, 'ad_import');
    }

    return $self;
}

sub execute {
    my ($self) = @_;

    my ($sql, @sqlargs) = $self->sql;

    $self->{query} = $self->_prepare($sql);
    if($self->{query}->execute(@sqlargs)) {
        return 1;
    } else {
        print "<font color='red'>Problem executing the query: ".$self->{query}->errstr."</font><br>";
    }

    return 0;
}

sub next {
    my ($self) = @_;
    return $self->{query}->fetchrow_hashref($self->{tablesearch}->{column_fetch_format});
}

sub column_names {
    my ($self) = @_;

    return $self->{saved_column_names} if ($self->{saved_column_names});

    my $ts = $self->{tablesearch};
    my $column_names;

    if ($self->{query}) {
        $column_names = $self->{query}->{$ts->{column_fetch_format}};
    }
    elsif (defined($ts->{field_list})) {
        $column_names = $ts->{field_list};
    }
    else {
        my $sql = $ts->{sql} || "SELECT * FROM $ts->{table}";
        if ($ts->{storage_engine} eq 'mysql') {
            $sql .= " LIMIT 1";
        }
        elsif ($ts->{storage_engine} eq 'oracle') {
            if ($ts->{sql} && $ts->{sql} =~ /WHERE/i) {
                $sql .= " AND ROWNUM = 1";
            }
            else {
                $sql .= " WHERE ROWNUM = 1";
            }
        }
        else {
            die "column_names can't handle storage engine $ts->{storage_engine}";
        }
        my $query = $self->_prepare($sql);
        $query->execute(@{$self->{tmp}->{sqlargs} or []}) or die $query->errstr;
        $column_names = $query->{$ts->{column_fetch_format}};
    }

    $self->{saved_column_names} = $column_names;

    return $column_names;
}

sub distinct_filter_values {
    my ($self) = @_;
    my $ts = $self->{tablesearch};

    # Allow overriding filter values
    return @{$ts->{filter_values}} if ($ts->{filter_values});

    my $dbh = $self->_dbh;

    $self->{exec_args} = [ ];

    my @results;

    $ts->{filter_name_field} = $ts->{filter_field} unless (defined $ts->{filter_name_field});

    my $sql = "SELECT DISTINCT $ts->{filter_field}, $ts->{filter_name_field} FROM $ts->{table} ";
    $sql .= $self->do_exec_args($ts->{filter_join}) if ($ts->{filter_join});
    my $query = $self->_prepare($sql);
    $query->execute(@{$self->{exec_args}}) or die "unable to execute $sql: ".$query->errstr;
    while(my ($field_value,$field_name) = $query->fetchrow_array) {
        push @results, [$field_value, $field_name];
    }

    return @results;
}

sub found_rows {
    my ($self) = @_;

    my $query = $self->_found_rows_query;
    my ($rows) = $query->fetchrow_array;

    return $rows;
}

sub _found_rows_query {
    my ($self) = @_;
    my $dbh = $self->_dbh;

    my $query = $self->_prepare($self->{tmp}->{dbi_found_rows_sql});
    $query->execute(($self->{tablesearch}->{no_calc_found_rows} ? @{$self->{tmp}->{sqlargs}} : ())) or die "can't execute the query: ".$query->errstr;

    return $query;
}

sub _dbh
{
    my $self = shift;
    my $ts = $self->{tablesearch};

    if (defined($ts->{dbh})) {
        return $ts->{dbh};
    } elsif (defined($ts->{data})) {
        $ts->{dbh} = DBI->connect('dbi:AnyData(RaiseError=>1):');
    } else {
        $ts->{dbh} = $HTML::Mason::Commands::dbh;
    }

    die 'No dbh' if (!$ts->{dbh});

    return $ts->{dbh};
}

sub _prepare
{
    my ($self, $sql) = @_;
    my $sth = $self->_dbh->prepare($sql) or die "Can't prepare: " . $self->_dbh->errstr;
    return $sth;
}

sub _limit
{
    my ($self, $sql, $limit, $offset) = @_;
    if (!defined($offset)) {
        $offset = 0;
    }
    my $ts = $self->{tablesearch};
    if ($ts->{storage_engine} eq 'mysql') {
        return $sql . " LIMIT " . (defined($offset) ? "$offset, " : "") . $limit;
    }
    elsif ($ts->{storage_engine} eq 'oracle') {
        my $query = "SELECT * FROM ( SELECT query.*, ROWNUM ts_rnum FROM ( $sql ) query WHERE ROWNUM < " . ($limit + $offset) . " ) WHERE ts_rnum >= $offset ORDER BY ts_rnum";
        $self->{tablesearch}->{field_params}->{ts_rnum}->{hidden} = 1;
        return $query;
    }
    else {
        die "_limit can't handle storage engine $ts->{storage_engine}";
    }
}

sub _clean_sql
{
    my ($self, $sql) = @_;
    return $self->{tablesearch}->clean_sql($sql);
}

sub _quote
{
    my ($self, $sql) = @_;
    return $self->{tablesearch}->{quote_char} . $self->_clean_sql($sql) . $self->{tablesearch}->{quote_char};
}

sub do_exec_args {
    my ($self, $arr) = @_;

    unless (ref $arr) {
        return $arr;
    }

    my @array = @$arr;
    my $sql = shift @array;

    while (@array) {
        push @{ $self->{exec_args} }, shift(@array);
    }

    return $sql;
}

sub sql {
    # XXX no error is throw if table isn't set, for example
    my $self = shift;
    my $ts = $self->{tablesearch};
    $self->{exec_args} = [ ];

    my ($sql, $sql_sort, $join, $query, $where, $group);

    my $dbh = $self->_dbh;

    my $sort_prefix = '';
    my $secondary_sort = '';

    # Keep these in the correct order, otherwise exec_args get jumbled

    # JOIN

    if ($ts->{joins}) {
        my @joins = @{$ts->{joins}};
        while (@joins) {
            my $join_table = shift @joins;
            my $on = $self->do_exec_args(shift @joins);
            $join .= " LEFT JOIN $join_table ON ($on) ";
        }
    } else {
        $join = "";
    }

    # WHERE
    $where = 'WHERE 1=1';
    $where = $self->do_exec_args($ts->{where})
        if ($ts->{where});

    $where = "WHERE $where"
        if ($where !~ /^\s*WHERE/i);

    if ($ts->{search}) {
        if ($ts->{insecure} && $ts->{search} =~ m/^WHERE /) {
            $where = $ts->{search};
        } else {
            my @search_field_list;
            if (defined($ts->{search_fields})) {
                @search_field_list = @{$ts->{search_fields}};
            }
            elsif (defined($ts->{field_list})) {
                @search_field_list = map { my $field = $_; $field =~ s/^(.*)\s+as\s+.+?$/$1/is; $field; } @{$ts->{field_list}};
            }
            else {
                @search_field_list = @{$self->column_names};
            }
            if (defined($ts->{excluded_search_fields})) {
                @search_field_list = grep { my $field = $_; ! grep { $field eq $_ } @{$ts->{excluded_search_fields}}; } @search_field_list;
            }
            my @terms = split(/ /, $ts->{search});
            for my $term (@terms) {
                if ($term =~ /^\+/) {
                    $term =~ s/^\+//;
                    $where .= " AND (" . join(" = '$term' OR ", @search_field_list) . " = '$term')";
                }
                else {
                    $where .= " AND (" . join(" LIKE '%$term%' OR ", @search_field_list) . " LIKE '%$term%')";
                }
            }
        }
    }
    if ($ts->{filter} && $ts->{filter} ne 'all') {
        $where = " WHERE 1=1 " unless $where;
        if (defined($ts->{filter_groups}) && defined($ts->{filter_groups}->{$ts->{filter}})) {
            $where .= " AND (1=0";
            foreach my $match (@{$ts->{filter_groups}->{$ts->{filter}}->{matches}}) {
                $where .= " OR $ts->{filter_field} = ?";
                push @{ $self->{exec_args} }, $match;
            }
            $where .= ") ";
        } else {
            $where .= " AND $ts->{filter_field} = ?";
            push @{ $self->{exec_args} }, $ts->{filter};
        }
    }

    if ($ts->{sort_prefix_field}) {
        $sort_prefix = $ts->{sort_prefix_field};
        $sort_prefix .= ' ' . $ts->{sort_prefix_dir} if ($ts->{sort_prefix_dir});
        $sort_prefix .= ',';
    }

    if ($ts->{sort} && defined($ts->{field_params}->{$ts->{sort}}->{secondary_sort_field})) {
        $secondary_sort = ", " . $ts->{field_params}->{$ts->{sort}}->{secondary_sort_field} . " $ts->{sort_order}";
    }

    if (defined($ts->{group_by})) {
        $group = $ts->{group_by};
    }
    else {
        $group = '';
    }

    if ($ts->{sql}) {
        $sql = $self->do_exec_args($ts->{sql});
    }
    else {
        $sql = "SELECT ";

        if (defined($ts->{field_list}) && scalar(@{$ts->{field_list}})) {
            $sql .= join(",", @{$ts->{field_list}});
        } else {
            $sql .= "*";
        }

        $sql .= " FROM $ts->{table} $join $where $group";
    }

    if ($ts->{no_calc_found_rows}) {
        if (!$ts->{sql} && ($ts->{data} || !$group)) {
            $self->{tmp}->{dbi_found_rows_sql} = "SELECT COUNT(*) FROM $ts->{table} $join $where";
        }
        else {
            $self->{tmp}->{dbi_found_rows_sql} = "SELECT COUNT(*) FROM ($sql) t";
        }
    } else {
        $self->{tmp}->{dbi_found_rows_sql} = "SELECT FOUND_ROWS()";
    }

    $sql .= ($ts->{sort} ? " ORDER BY $sort_prefix $ts->{sort} $ts->{sort_order} $secondary_sort" : "");

    if (!$ts->{no_calc_found_rows}) {
        $sql =~ s/^\s*SELECT/SELECT SQL_CALC_FOUND_ROWS/i unless ($sql =~ /SQL_CALC_FOUND_ROWS/i);
    }

    $sql = $self->_limit($sql, $ts->{limit}, $ts->{start})
        if (!$self->{no_limit} && !$ts->{no_limit});

    $self->{tmp}->{sqlargs} = $self->{exec_args};

    return ($sql, @{ $self->{exec_args} });
}

1;

