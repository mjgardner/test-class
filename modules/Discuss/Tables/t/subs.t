#! /usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::DBI;
use Discuss::DBI;

my $dbh = Discuss::DBI->connect or die "cannot create DBH";

BEGIN {
	use_ok('Discuss::Tables', qw(create_table drop_table clear_table
		list_tables clear_all_tables));
};

my @tables = list_tables();
$dbh->do("drop table if exists $_") foreach @tables;
table_absent($dbh, $_) foreach @tables;

create_table($dbh, @tables);
table_exists($dbh, $_) foreach @tables;

drop_table($dbh, @tables);
table_absent($dbh, $_) foreach @tables;

clear_table($dbh, @tables);
table_exists($dbh, $_) foreach @tables;

drop_table($dbh, $tables[0]);
clear_table($dbh, @tables);
table_exists($dbh, $_) foreach @tables;

drop_table($dbh, @tables);
table_absent($dbh, $_) foreach @tables;

clear_all_tables($dbh);
table_exists($dbh, $_) foreach @tables;
