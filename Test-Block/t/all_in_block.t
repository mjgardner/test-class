use strict;
use warnings;
use Test::More tests => 6;
use Test::Block qw($Plan);

{
	local $Plan = 1;
	ok( Test::Block->all_in_block, 'true at start');
};
{
	local $Plan = 1;
	ok( Test::Block->all_in_block, 'true after a block');
};
ok( Test::Block->all_in_block, 'true immediately outside a block');
ok(!Test::Block->all_in_block, 'false after non-block test');
{
	local $Plan = 1;
	ok( !Test::Block->all_in_block, 'still false in next block');
};
{
	local $Plan = 1;
	ok( !Test::Block->all_in_block, 'still false in following block');
};
