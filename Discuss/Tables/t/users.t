#! /usr/bin/perl -T

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Test::DBI;
use Discuss::DBI;

my $dbh = Discuss::DBI->connect or die "cannot create DBH";

BEGIN {
	use_ok('Discuss::Tables', qw(create_table drop_table clear_table));
};

my $table = 'users';
$dbh->do("drop table if exists $table");

dies_ok { drop_table($dbh, $table) }	"cannot drop $table that does not exist";

lives_ok { create_table($dbh, $table) } "$table table created";
table_exists $dbh, $table;
row_count_is($dbh, $table, 0, "$table is empty");

$dbh->do("insert into $table (email,name,password,banned) values ('email','name','password',0)");
row_count_is($dbh, $table, 1, "one row added to $table");
dies_ok {$dbh->do("insert into $table (email,name,password,banned) values ('email','name2','password',0)")} 'cannot make duplicate email';
dies_ok {$dbh->do("insert into $table (email,name,password,banned) values ('email2','name','password',0)")} 'cannot make duplicate name';
select_ok($dbh, qq{
	select user_id,email,name,password,banned from $table where (
		user_id=1 and email='email' and name='name' and password='password' and banned=0
	)
}, 1, 'row added properly');

lives_ok { clear_table($dbh, $table) } "clear_table when $table table exists";
row_count_is($dbh, $table, 0, "$table cleared");

dies_ok { create_table($dbh, $table) }	"cannot create $table table that exists";

lives_ok { drop_table($dbh, $table) }	"$table table dropped";
table_absent $dbh, $table;

lives_ok { clear_table($dbh, $table) } "clear_table when $table table absent";
table_exists $dbh, $table;

$dbh->disconnect;