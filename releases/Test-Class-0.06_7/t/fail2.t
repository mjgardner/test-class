#! /usr/bin/perl -T

use strict;
use warnings;
use Test;
use Test::Builder;
use Fcntl;
use IO::File;
use POSIX qw(_exit);


package Object;
sub new {return(undef)};


package Object::Test;
use base qw(Test::Class);
use Test::More;

sub _test_new : Test(3) {
	my $self = shift;
	isa_ok(Object->new, "Object") 
		|| $self->FAIL_ALL('cannot create Objects');
};


package main;

plan tests => 9;

my $io = IO::File->new_tmpfile or die "couldn't create tmp file ($!)\n";
my $Test = Test::Builder->new;				
$Test->output($io);
$Test->failure_output($io);

$ENV{TEST_VERBOSE}=0;
Object::Test->runtests;
END {
	$|=1;
	seek $io, SEEK_SET, 0;
    my $SEP = $^O eq "MSWin32" ? '\\' : '/';
	while (my $actual = <$io>) {
		chomp($actual);
		my $expected=<DATA>; chomp($expected);
		$expected =~ s!/!$SEP!gs;
		ok($actual, $expected);
	};

	ok($?, 3);
	_exit(0); # need to stop Test::Builder's $? tweak
};

__DATA__
1..3
not ok 1 - The object isa Object
#     Failed test (t/fail2.t at line 22)
#     The object isn't defined
not ok 2 - cannot create Objects
#     Failed test (t/fail2.t at line 22)
not ok 3 - cannot create Objects
#     Failed test (t/fail2.t at line 22)
