#! /usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::DBI;
use Test::Exception;
use Scalar::Util qw(refaddr);
use DBI;

BEGIN {
	use_ok 'Discuss::DBIObject';
	use_ok 'Discuss::DBIObject::Iterator';
};

my $dbh = DBI->connect(undef, undef, undef, {
	RaiseError => 1, PrintError=>0, ShowErrorStatement=>1
});
my $table1 = "table1";
my $table2 = "table2";

eval { $dbh->do("drop table $table1") };
eval { $dbh->do("drop table $table2") };

$dbh->do( qq{
	CREATE TABLE $table1 (
		id SMALLINT UNSIGNED NOT NULL auto_increment,
		name VARCHAR(80) NOT NULL,
		status INT NOT NULL,
		live INT NOT NULL,
		PRIMARY KEY(id)
	) TYPE = InnoDB
});
$dbh->do( qq{
	CREATE TABLE $table2 (
		name VARCHAR(80) NOT NULL,
		answer INT NOT NULL,
		PRIMARY KEY(name)
	) TYPE = InnoDB
});

$dbh->do( qq{INSERT INTO $table2 (name,answer) VALUES ('t1',42)} );
$dbh->do( qq{INSERT INTO $table2 (name,answer) VALUES ('t2',24)} );

{	
	package Test;
	use base qw(Discuss::DBIObject);
	sub table { $table1 };
	sub columns { [ qw(id name status live) ] };
	sub default { [ status => 42, live => sub { 2+2 } ] };
	sub required { [ qw(name) ] };
};

is(Test->iterator_class, 'Discuss::DBIObject::Iterator',
	'iterator_class');

{
	is(Test->primary, 'id', 'primary');
	
	dies_ok { Test->new(dbh => $dbh) } 'required fields checked';
	dies_ok { Test->new(name => 't1') } 'dbh checked';
	
	my $o1 = Test->new(dbh => $dbh, name => 't1');
	isa_ok $o1, 'Test', 'o1';
	is $$o1->{name}, 't1', 'set field defined';
	is $$o1->{status}, 42, 'default field defined';
	is $$o1->{live}, 4, 'default run-time field defined';
	select_ok($dbh, 
		"select * from $table1 where name = 't1' and status = 42", 
		1, 'new object in database'
	);
	
	my $o2 = Test->new(dbh => $dbh, name => 't2', status => 0);
	is $$o2->{status}, 0, 'default field overridden';
	select_ok($dbh, 
		"select * from $table1 where name = 't2' and status = 0",
		1, 'overridden object in database'
	);
	
	my $o3 = Test->new(dbh => $dbh, name => 't3', status => 99);
	
	my $i = Test->iterator(dbh => $dbh);
	isa_ok $i, 'Discuss::DBIObject::Iterator', 
			'default iterator (asc by primary)';
	is $i->class, 'Test', 'iterator class set';
	
	my @list;
	while (my $item = $i->next) { push @list, $$item->{name} };
	ok( eq_set( \@list, [ qw(t1 t2 t3) ]), 'raw iterator works' );
		
	my $i2 = Test->iterator(dbh => $dbh)->order('desc')
			->order_by('status');
	isa_ok $i2, 'Discuss::DBIObject::Iterator', 'desc by status';
	is ${$i2->next}->{name}, 't3', 't3 is first';
	is ${$i2->next}->{name}, 't1', 't1 is second';
	is ${$i2->next}->{name}, 't2', 't2 is third';
	is $i2->next, undef, 'and that is it';
	
	my $i3 = Test->iterator(dbh => $dbh)->where(status => 99);
	isa_ok $i3, 'Discuss::DBIObject::Iterator', 'where status is 99';
	my $next = $i3->next;
	ok($$next->{dbh}, 'got dbh');
	isa_ok $next, 'Test', 'result of iterator';
	is $$next->{name}, 't3', 't3 is third';
	is refaddr($$next), refaddr($$o3), 't3 in object pool';
	is $i3->next, undef, 'and that is it';
	
	my $i4 = Test->iterator(dbh => $dbh)->limit(2)->order_by('id')
			->order('asc');
	isa_ok $i4, 'Discuss::DBIObject::Iterator', 'asc by primary limit 2';
	is ${$i4->next}->{name}, 't1', 't1 is first';
	is ${$i4->next}->{name}, 't2', 't2 is second';
	is $i4->next, undef, 'and that is it';
	
	my $list = Test->iterator(dbh => $dbh)->limit(2)->order_by('id')
			->order('asc')->as_list;
	is_deeply [map {$$_->{name}} @$list], [qw(t1 t2)], 'as_list worked';
	
	my $new_o1 = Test->fetch( dbh => $dbh, id => $$o1->{id} );
	is refaddr($$new_o1), refaddr($$o1), 'fetch returned pooled object';
	
	my $refaddr = do {
		my $o4 = Test->new(dbh => $dbh, name => 't4', status => 67);
		refaddr ($$o4);
	};
	my $new_o4;
	lives_ok {$new_o4 = Test->fetch(dbh => $dbh, id => 4)} 'fetched o4';
	is $$new_o4->{status}, 67, 'data retrieved';
	isnt refaddr($$new_o4), $refaddr, 'fetch was not from pool';
	
	throws_ok { Test->fetch(dbh => $dbh, id => 99999) }
			'Discuss::Exception::NoSuchObject', 
				'cannot fetch non-existing object';
	is(Test->pool_size, 4, 'four objects in pool');
	
	my $i5 = Test->iterator(dbh => $dbh)->order_by('id')->order('asc')
			->join_with("$table1.name" => "$table2.name");
	isa_ok $i5, 'Discuss::DBIObject::Iterator', 'can join';
	is ${$i5->next}->{name}, 't1', 't1 is first';
	is ${$i5->next}->{name}, 't2', 't2 is second';
	is $i5->next, undef, 'and that is it';
	
	my $i6 = Test->iterator(dbh => $dbh)
		->join_with("$table1.name" => "$table2.name")
		->where("$table2.answer" => 42);
	isa_ok $i6, 'Discuss::DBIObject::Iterator', 
			'can use where on joined table';
	is ${$i6->next}->{name}, 't1', 't1 is first';
	is $i6->next, undef, 'and that is it';
	
	my $i7 = Test->iterator(dbh => $dbh)->where_op('>', status => 30)
			->order_by('id')->order('asc');
	isa_ok $i7, 'Discuss::DBIObject::Iterator', 'where_op';
	is ${$i7->next}->{name}, 't1', 't1 is second';
	is ${$i7->next}->{name}, 't3', 't3 is third';
	is ${$i7->next}->{name}, 't4', 't4 is third';
	is $i7->next, undef, 'and that is it';
	is $i7->next, undef, 'and it remains it';
	
	is(Test->pool_size, 4, 'four objects in pool');
	my $lazy_id = ${Test->new(dbh=>$dbh, name => 'lazy', status => 66)}->{id};
	is(Test->pool_size, 4, 'still four objects in pool');
	my $lazy = Test->fetch(dbh => $dbh, id => $lazy_id, lazy => 1);
	is(Test->pool_size, 5, 'five objects in pool');
	ok $lazy->is_lazy, 'object is lazy';
	is $$lazy->{id}, $lazy_id, 'primary exists on lazy load';
	is $$lazy->{status}, undef, 'status undef on lazy load';
	is $$lazy->{name}, undef, 'name undef on lazy load';
	$lazy->load;
	ok !$lazy->is_lazy, 'object no longer lazy';
	is $$lazy->{id}, $lazy_id, 'primary set after load';
	is $$lazy->{status}, 66, 'status set after load';
	is $$lazy->{name}, 'lazy', 'name set after load';
	is(Test->pool_size, 5, 'still five objects in pool');
};

{
	my $list = Test->iterator(dbh => $dbh)->where_in('id', 1..3)
			->order_by('id')->order('asc')->as_list;
	my @list = map {$$_->{id}} @$list;
	is_deeply \@list, [1,2,3], 'where_in';	
};

is(Test->pool_size, 0, 'no objects in pool');
my $list = Test->iterator(dbh => $dbh, lazy=>1)->as_list;
is(Test->pool_size, 5, 'five objects in pool');
is @$list, 5, 'five objects in list';
is grep({$_->is_lazy} @$list), 5, 'all objects lazy';
Test->load_all(@$list);
is grep({$_->is_lazy} @$list), 0, 'all objects loaded';

my $lazy_id = ${Test->new(dbh=>$dbh, name => 'foo', status => 66)}->{id};
my $lazy = Test->fetch(dbh => $dbh, id => $lazy_id, lazy => 1);
$dbh->do("delete from $table1 where id = $lazy_id");
throws_ok { $lazy->load } 'Discuss::Exception::NoSuchObject', 
	'cannot load lazy object not in database';

my $not_lazy = Test->new(dbh=>$dbh, name => 'not lazy', status => 66);
ok !$not_lazy->is_lazy, 'new objects are not lazy';
my $fetched = Test->iterator(dbh => $dbh, lazy=>1)
	->where(id => $$not_lazy->{id})->next;
is refaddr($$not_lazy), refaddr($$fetched), 'fetched copy identical';
ok !$not_lazy->is_lazy, 'object still not lazy';

$dbh->do("drop table $table1");
$dbh->do("drop table $table2");
$dbh->disconnect;
