use strict;
use warnings;
use Test::More tests => 6;
use Test::Builder;

BEGIN { use_ok 'Test::Block' };

is( Test::Block->block_count, 0, 'block count initially zero');

SKIP: {
	my $block = Test::Block->plan(tests => 2);
	pass('first expected test');
	pass('second expected test');
};

is( Test::Block->block_count, 1, 'block count updated');
is( Test::Builder->new, Test::Block->builder, 'builder' );