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

my $table = 'topics';
$dbh->do("drop table if exists $table");

dies_ok { drop_table($dbh, $table) }	"cannot drop $table that does not exist";

lives_ok { create_table($dbh, $table) } "$table table created";
table_exists $dbh, $table;
row_count_is($dbh, $table, 0, "$table is empty");

$dbh->do("insert into $table (name, board_id) values ('test topic', 0)");
row_count_is($dbh, $table, 1, "one row added to $table");
select_ok($dbh, qq{
	select topic_id,board_id,name,num_posts from $table where (
		topic_id=1 and board_id=0 and name='test topic' and num_posts=0
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