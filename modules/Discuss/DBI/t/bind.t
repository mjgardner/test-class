#! /usr/bin/perl

# Check row binding in a hash works okay 

use strict;
use warnings;
use DBI;
use Test::More tests => 9;

BEGIN { use_ok( 'Discuss::DBI' ) };

my $dbh = Discuss::DBI->connect;
isa_ok($dbh, 'DBI::db');

eval {
	eval { $dbh->do( 'DROP TABLE bind_test' ) };
	$dbh->do( "CREATE TABLE bind_test (x INT, x_squared INT) TYPE = InnoDB" );
	$dbh->do( "INSERT INTO bind_test VALUES (1,1)" );
	$dbh->do( "INSERT INTO bind_test VALUES (2,4)" );
	$dbh->do( "INSERT INTO bind_test VALUES (3,9)" );
	
	my $sth = $dbh->prepare( "SELECT x, x_squared from bind_test" );
	$sth->execute;
	my %row;
	$sth->bind_columns( \( @row{ @{$sth->{NAME_lc} } } ));
	my $x=0;
	while ($sth->fetch) {
		$x++;
		is($row{x}, $x, "x = $x");
		is($row{x_squared}, $x*$x, "x_squared = " . $x*$x);
	}
	is($x, 3, 'three rows fetched');
	
	$dbh->do( 'DROP TABLE bind_test' );
};
diag($DBI::errstr) if $@;
$dbh->disconnect;
