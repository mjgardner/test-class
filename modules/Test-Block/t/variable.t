use strict;
use warnings;
use Test::Builder::Tester tests => 1;
use Test::More;
use Test::Block;

test_out("ok 1 - remaining set");
test_out("not ok 2 - block inner expected 1 test(s) and ran 0");
test_fail(+8);
test_out("ok 3 - remaining updated");
test_out("ok 4 # skip last test");
test_out("ok 5 - block count correct");
SKIP: {
	local $Test::Block::Plan = 4;
	is( $Test::Block::Plan, 4, 'remaining set' );
	{
		local $Test::Block::Plan = { inner => 1 };
	}
	is( $Test::Block::Plan, 2, 'remaining updated' );
	skip 'last test', $Test::Block::Plan;
};
is( Test::Block->block_count, 2, 'block count correct');
test_test('$Test::Block::Plan');
