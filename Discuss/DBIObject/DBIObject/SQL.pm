package Discuss::DBIObject::SQL;
use strict;
use warnings;
use Discuss::Carp;

our $VERSION = '0.07';

sub new {
	my ($class, %param) = @_;
	bless {
		_dbh			=> $param{dbh} || confess("need dbh"),
		_select			=> [],
		_tables			=> {},
		_join			=> [],
		_where			=> {},
		_default_table	=> undef,
		_order_by		=> undef,
		_order			=> undef,
		_last			=> 'none',
		_sth			=> undef,
	}, $class;	
};

sub from {
	my ($self, $table) = @_;
	confess "bad table" unless defined($table) && $table =~ m/^\w+$/;
	$self->{_tables}->{$table} = 1;
	$self->{_default_table} ||= $table;
	return($self);
};

sub _normalise_columns {
	my $self = shift;
	my @columns = map {
		confess "undefined column" unless defined($_);
		my ($table, $column) = ( $_ =~ m/^(?:(\w+)\.)?(\w+)$/s );
		confess "illegal column ($_)" unless defined($column);
		$table ||=  $self->{_default_table} || confess "no default table";
		$self->from($table);
		"$table.$column";
	} @_;
	wantarray ? @columns : $columns[0];
};

sub order_by {
	my ($self, $column) = @_;
	$self->{_order_by} = _normalise_columns($self, $column);
	return($self);
};

sub _set_option {
	my ($self, $option, $regex, $value) = @_;
	confess "bad value" unless $value && $value =~ m/$regex/s;
	$self->{$option} = $value;
	return($self);
};

sub order {
	my ($self, $order) = @_;
	_set_option( $self, '_order', qr/^(asc|desc)$/, $order);
};

sub limit {
	my ($self, $limit) = @_;
	_set_option( $self, '_limit', qr/^\d+$/, $limit);
};

sub where_op {
	my ($self, $op, @terms) = @_;
	confess 'bad operation' unless $op && $op =~ m!^(=|>|<|>=|<=)$!s;
	confess 'odd number of terms' if @terms % 2;
	for(my $n=0; $n < @terms; $n+=2) { 
		$terms[$n] = _normalise_columns($self, $terms[$n])
	};
	push @{ $self->{_where}->{$op} }, @terms;
	return( $self );
};

sub where_in {
	my ($self, $column, @values) = @_;
	$column = _normalise_columns($self, $column);
	push @{$self->{_where_in}->{$column}}, @values;
	return( $self );
};

sub where {
	my $self = shift;
	$self->where_op('=', @_);
};

sub select {
	my $self = shift;
	push @{ $self->{_select} }, _normalise_columns($self, @_);
};

sub join_with {
	my $self = shift;
	confess 'odd number of terms' if @_ % 2;
	push @{$self->{_join}}, _normalise_columns($self, @_);
	return($self);
};

sub _from_sql {
	join(',', keys %{shift->{_tables}});
};

sub _select_sql {
	join(',',  @{shift->{_select}});
};

sub _limit_sql {
	my $limit = shift->{_limit};
	$limit ? "limit $limit" : "";
};

sub _where_sql {
	my $self = shift;
	my @terms;
	push @terms, join('=', splice(@{$self->{_join}}, 0, 2) )
			while @{$self->{_join}};
	while (my ($op, $where) = each %{$self->{_where}}) {
		my %where = @$where;
		push @terms, map {"$_ $op ?"} keys %where;
	};
	while (my ($column, $values) = each %{$self->{_where_in}}) {
		push @terms, "$column in (" . join(',', ('?') x @$values) . ")";
	};
	my $where_sql = join(' and ', @terms);
	$where_sql = "where $where_sql" if $where_sql;
	return($where_sql);
};

sub _values {
	my $self = shift;
	my @values;
	while (my ($op, $where) = each %{$self->{_where}}) {
		my %where = @$where;
		push @values, values %where;
	};
	while (my ($column, $values) = each %{$self->{_where_in}}) {
		push @values, @$values;
	};
	return(@values);
};

sub _order_by_sql {
	my $self = shift;
	return '' unless my $order_by = $self->{_order_by};
	my $order = $self->{_order} || '';
	return( "order by $order_by $order" );
};

sub _sql {
	my $self = shift;
	join( ' ', "select", _select_sql($self), "from", _from_sql($self),
		_where_sql($self), _order_by_sql($self), _limit_sql($self) );
};

sub _sth {
	my $self = shift;
	return $self->{_sth} if $self->{_sth};
	$self->{_sth} = $self->{_dbh}->prepare( _sql($self) );
	$self->{_sth}->execute( _values($self) );
	return( $self->{_sth} );
};

sub next {
	my $self = shift;
	return undef unless $self->{_last};
	my $row = $self->{_last} = _sth($self)->fetchrow_hashref;
	return( $row ? {%$row} : undef );
};

sub as_list {
	my $self = shift;
	my @list;
	while (my $next = $self->next) {push @list, $next};
	return \@list;
};

1;