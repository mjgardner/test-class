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

my $table = 'posts';
$dbh->do("drop table if exists $table");

dies_ok { drop_table($dbh, $table) }	"cannot drop $table that does not exist";

lives_ok { create_table($dbh, $table) } "$table table created";
table_exists $dbh, $table;
row_count_is($dbh, $table, 0, "$table is empty");

$dbh->do("insert into $table (topic_id,content,user_id,date) values (2,'content',3,4)");
row_count_is($dbh, $table, 1, "one row added to $table");
select_ok($dbh, qq{
	select post_id,topic_id,content,user_id from $table where (
		post_id=1 and topic_id=2 and content='content' and user_id=3 and date=4
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