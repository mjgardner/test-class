#! /usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Discuss::DBI;

BEGIN {
	use_ok 'Discuss::Base';
	use_ok 'Discuss::Base::Iterator';
};


my $dbh = Discuss::DBI->connect;

my $table = "test";

eval { $dbh->do("drop table $table") };

$dbh->do( qq{
	CREATE TABLE $table (
		ident SMALLINT UNSIGNED NOT NULL auto_increment,
		name VARCHAR(80) NOT NULL,
		html VARCHAR(80) NOT NULL,
		live INT NOT NULL,
		PRIMARY KEY(ident)
	) TYPE = InnoDB
});

{	
	package Example::Class;
	use base qw(Discuss::Base);
	sub table { $table };
	sub columns { [ qw(ident name live html ) ] };
	sub default { [ 
		live => sub { 2+2 }, html => '<p>hello</p>'
	] };
	sub required { [ qw(name) ] };
	sub is_html { [ 'html' ] };
};

is( Example::Class->iterator_class, 'Discuss::Base::Iterator',
	'iterator_class');

{
	my $o1 = Example::Class->new(dbh => $dbh, name => 't1');
	my $o2 = Example::Class->new(dbh => $dbh, name => '<foo>');
	isa_ok $o1, 'Example::Class', 'o1';
	isa_ok $o2, 'Example::Class', 'o2';
	is $o1->name, 't1', 'set field defined';
	is $o2->name, '<foo>', 'objects are treated seperately';
	is $o1->html, '<p>hello</p>', 'default field defined';
	is $o1->live, 4, 'default run-time field defined';

	{
		local $Discuss::Base::Escape_html = 1;	
		is $o2->name, '&lt;foo&gt;', 'html escaping working';
		is $o2->html, '<p>hello</p>', 'except for html fields';
	};
	
	is(Example::Class->pool_size, 2, 'two objects in pool');
};

is(Example::Class->pool_size, 0, 'no objects in pool');

is_deeply(Discuss::Base->is_html, [], 'is_html defaults to nothing');

isa_ok my $i = Example::Class->iterator(dbh => $dbh), 'Discuss::Base::Iterator';
isa_ok $i, 'Discuss::DBIObject::Iterator';
is $i->class, 'Example::Class', 'iterator class set';

my $fake = bless {}, 'Discuss::Base';
dies_ok {$fake->iterator(dbh => $dbh)} 'cannot make iterator from object';
bless $fake, 'SomethingElseToAvoidBogusDESTROYinCleanup';

my $lazy_id = Example::Class->new(dbh => $dbh, name => 'lazy')->ident;
my $lazy_object = Example::Class->iterator(dbh => $dbh, lazy=>1)
	->where(ident => $lazy_id)->next;
isa_ok $lazy_object, 'Example::Class', 'lazy object';
ok $lazy_object->is_lazy, 'is lazy';
is $lazy_object->ident, $lazy_id, 'ident works on lazy object';
ok $lazy_object->is_lazy, 'still lazy';
is $lazy_object->name, 'lazy', 'name works on lazy object';
ok !$lazy_object->is_lazy, 'not lazy anymore';

eval { $dbh->do("drop table $table") };
$dbh->disconnect;
