#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Class::Load' );
}

diag( "Testing Test::Class::Load $Test::Class::Load::VERSION, Perl $], $^X" );
