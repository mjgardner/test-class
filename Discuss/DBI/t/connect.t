#! /usr/bin/perl 

use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;
use Scalar::Util qw(refaddr);

BEGIN { use_ok('Discuss::DBI') };

my ($dsn, $user, $pass) = 
		map { $ENV{"DBI_$_"} || 'undef' } qw(DSN USER PASS);

my $dbh = Discuss::DBI->connect;
isa_ok($dbh, 'DBI::db')
		or diag("DBI_DSN = $dsn, DBI_USER = $user, DBI_PASS = $pass");
throws_ok {$dbh->do('haddock')} 'Discuss::Exception::DBI', 'Discuss::Exception::DBI thrown';
like( $@->error, qr/haddock/, "error found" );

my $dbh2 = Discuss::DBI->connect;
is( refaddr($dbh), refaddr($dbh2), 'it is a singleton' );

$dbh->disconnect if $dbh;