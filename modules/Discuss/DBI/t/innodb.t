#! /usr/bin/perl

# Check that we have InnoDB support 

use strict;
use warnings;
use Test::More tests => 4;
use DBI;
use Test::DBI;

BEGIN { use_ok( 'Discuss::DBI' ) };

my $dbh = Discuss::DBI->connect;
isa_ok($dbh, 'DBI::db');

eval {
	eval { $dbh->do( 'DROP TABLE innodb_test' ) };
	$dbh->do( "CREATE TABLE innodb_test (id INT) TYPE = InnoDB" );
	$dbh->begin_work;
	$dbh->do( "INSERT INTO innodb_test VALUES (1)" );
	$dbh->do( "INSERT INTO innodb_test VALUES (2)" );
	$dbh->do( "INSERT INTO innodb_test VALUES (3)" );
	row_count_is($dbh, 'innodb_test', 3, '3 rows added');
};
diag($DBI::errstr) if $@;

eval {
	$dbh->rollback;
	row_count_is($dbh, 'innodb_test', 0, 'rows deleted after rollback');
	$dbh->do( 'DROP TABLE innodb_test' );
};
diag($DBI::errstr) if $@;
$dbh->disconnect;
