use strict;
use warnings;
use Test::Builder::Tester tests => 6;
use Test::More;
use Test::Block;

test_out('ok 1');
{
	my $block = Test::Block->plan(1);
	ok(1);
}
test_test("count okay");


test_out('ok 1');
test_out('not ok 2 - block 2 expected 2 test(s) and ran 1');
test_fail(+2);
{
	my $block = Test::Block->plan(2);
	ok(1);
}
test_test("too few tests");


test_out('ok 1');
test_out('ok 2');
test_out('not ok 3 - block 3 expected 1 test(s) and ran 2');
test_fail(+2);
{
	my $block = Test::Block->plan(1);
	ok(1);
	ok(1);
}
test_test("too many tests");


test_out('ok 1');
test_out('ok 2 # skip test');
test_out('ok 3 # skip test');
SKIP: {
	my $block = Test::Block->plan(3);
	ok(1);
	skip "test" => $block->remaining;
}
test_test("works with skipped tests");


test_out('ok 1');
{
	my $block = Test::Block->plan(1);
	{
		my $block = Test::Block->plan(1);
		ok(1);
	}
}
test_test("nested blocks");

test_out('ok 1');
test_out("not ok 2 - block foo expected 2 test(s) and ran 1");
test_fail(+2);
{
	my $block = Test::Block->plan(foo => 2);
	ok(1);
}
test_test("named block");
