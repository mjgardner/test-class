#! /usr/bin/perl -T

use strict;
use warnings;

package Local::Test;
use base qw(Test::Class);

use Test;
use Test::Builder;
use Fcntl;
use IO::File;

plan tests => 6;

sub _only : Test(setup => 1) {
	my $self = shift;
	$self->builder->ok(1==1);
	$self->SKIP_ALL("skippy");
};

sub test : Test(3) { die "this should never run!" };

my $io = IO::File->new_tmpfile or die "couldn't create tmp file ($!)\n";
my $Test = Test::Builder->new;				
$Test->output($io);
$Test->failure_output($io);

$ENV{TEST_VERBOSE}=0;
Local::Test->runtests;

END {
	seek $io, SEEK_SET, 0;
	while (my $actual = <$io>) {
		chomp($actual);
		my $expected=<DATA>; chomp($expected);
		ok($actual, $expected);
	};

	ok($?, 0, "exit value okay");
	$?=0;
};

__DATA__
1..4
ok 1 - test
ok 2 # skip skippy
ok 3 # skip skippy
ok 4 # skip skippy
