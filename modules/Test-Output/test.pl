#! /usr/bin/perl -w

use strict;
use Test::More tests => 10;
use Test::Output;

output_is     {print "hello\n"} "hello\n", STDOUT, "output_is pass";
output_isnt   {print "there\n"} "hello\n", STDOUT, "output_isnt pass";
output_like   {print "hello\n"} '/hello/', STDOUT, "output_like pass";
output_unlike {print "there\n"} '/hello/', STDOUT, "output_unlike pass";

TODO: {
	local $TODO = "this is meant to fail";
	output_is     {print "there\n"} "hello\n", STDOUT, "output_is fail";
	output_isnt   {print "hello\n"} "hello\n", STDOUT, "output_isnt fail";
	output_like   {print "there\n"} '/hello/', STDOUT, "output_like fail";
	output_unlike {print "hello\n"} '/hello/', STDOUT, "output_unlike fail";
};

sub caller_print {
	my $caller = caller(1);
	print $caller ? $caller : "no caller\n";
};

output_is { caller_print() } "no caller\n", STDOUT, "tests at right level";

is(Test::Output->last, "no caller\n", "last output");
