#! /usr/bin/perl -w

use strict;
use Test;
use Fcntl;
use IO::File;
use Test::Builder;
use POSIX qw(_exit);

package Object::Test;
use base 'Test::Class';
use Test::More;

sub setup : Test(setup) {
	die "died before plan set\n";
};

sub test : Test {
	ok(1==1, 'test just here to get setup method run');
};


package main;

my $io = IO::File->new_tmpfile or die "couldn't create tmp file ($!)\n";
my $Test = Test::Builder->new;				
$Test->output($io);
$Test->failure_output($io);
$ENV{TEST_VERBOSE}=0;
Object::Test->runtests;

plan tests => 4;

seek $io, SEEK_SET, 0;
while (my $actual = <$io>) {
	chomp($actual);
	my $expected=<DATA>; chomp($expected);
	ok($actual, $expected);
};

_exit(0);

__DATA__
1..1
not ok 1 - setup (for test method 'test') died (died before plan set)
#     Failed test (t/die_before_plan.t at line 30)
ok 2 - test just here to get setup method run
