#! /usr/bin/perl

use strict;
use warnings;

BEGIN {
	use Test::Builder;
	use Test::Harness;
	Test::Builder->skip_all("need Test::Harness >= 2.03") 
			unless $Test::Harness::VERSION >= 2.03;
	use Test::More tests => 4;
	use_ok( 'Test::Exception' );
};

sub works {return shift};
sub dies { die 'oops' };

lives_and {is works(42), 42} 'lives_and, no_exception & success';

TODO: {
	local $TODO = 'we expect this test to fail';
	lives_and {is works(42), 24}	'lives_and, no_exception & failure';
	lives_and {is dies(42), 42}		'lives_and, exception';
};
