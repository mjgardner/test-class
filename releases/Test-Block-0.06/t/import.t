use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Test::Block', qw($Plan) };

{
	local $Plan = 2;
	isa_ok( $Plan, 'Test::Block', '$Plan' );
	is $Plan, 1, '$Plan holds remaining number of tests';
}
