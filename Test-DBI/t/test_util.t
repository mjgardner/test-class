#! /usr/bin/perl 

use strict;
use warnings;
use Test::More tests => 8;

BEGIN { use_ok( 'Test::DBI' ) };

my $dbh = DBI->connect(undef, undef, undef, { 
	RaiseError	=> 1,
	PrintError	=> 0,
}) or die $DBI::errstr;                                                 

eval {
	$dbh->do( 'DROP TABLE IF EXISTS test_dbi_test' );
	table_absent( $dbh, 'test_dbi_test' );

	$dbh->do( "CREATE TABLE test_dbi_test (id INT)" );
	table_exists( $dbh, 'test_dbi_test' );

	row_count_is( $dbh, 'test_dbi_test', 0 );

	$dbh->do( "INSERT INTO test_dbi_test VALUES (1)" );
	row_count_is( $dbh, 'test_dbi_test', 1 );

	$dbh->do( "INSERT INTO test_dbi_test VALUES (2)" );
	row_count_is( $dbh, 'test_dbi_test', 2 );

	select_ok($dbh, 'select id from test_dbi_test where id=1', 1);

	select_ok($dbh, 'select id from test_dbi_test where id=99', 0);

	$dbh->do( 'DROP TABLE test_dbi_test' )
};
diag($DBI::errstr) if $@;

$dbh->disconnect;


