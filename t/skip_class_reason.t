#! /usr/bin/perl -T

use strict;
use warnings;
use Test::Class;
use Test;
use Fcntl;
use IO::File;
use Test::Builder;

{
    package Foo::Test;
    use base qw(Test::Class);
    use Test::More;

    sub skipped_with_reason : Test( 3 )  { fail( "this should not run" ) };
    __PACKAGE__->SKIP_CLASS( 'because SKIP_CLASS returned a string' );
}

{
    package Bar::Test;
    use base qw(Test::Class);
    use Test::More;

    sub skipped_with_reason : Test( 3 )  { fail( "this should not run" ) };
    __PACKAGE__->SKIP_CLASS( 1 );
}

plan tests => 3;

my $io = IO::File->new_tmpfile or die "couldn't create tmp file ($!)\n";
my $Test = Test::Builder->new;				
$Test->output($io);
$Test->failure_output($io);

$ENV{TEST_VERBOSE}=0;

Test::Class->runtests;

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
1..1
ok 1 # skip because SKIP_CLASS returned a string
