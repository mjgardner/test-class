use strict;
use warnings;
use Test::More tests => 5;
use Test::Builder;

BEGIN { use_ok 'Test::Block' };

is( Test::Block->block_count, 0, 'block count initially zero');

SKIP: {
	my $block = Test::Block->plan(1);
	pass('pass');
};

is( Test::Block->block_count, 1, 'block count updated');
is( Test::Builder->new, Test::Block->builder, 'builder' );