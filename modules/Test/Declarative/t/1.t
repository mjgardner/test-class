use Test::More 'no_plan';

BEGIN { use_ok('Test::Declarative') };

sub test_number_is {
	my $expected = shift;
	my $actual = Test::More->builder->current_test;
	is($actual, $expected, "current test number is $expected");
	return($actual+1);
};

my $n = Test::More->builder->current_test;

