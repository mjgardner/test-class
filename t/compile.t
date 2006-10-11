#! /usr/bin/perl -T

use strict;
use warnings;
use IO::File;
use Fcntl;

use base qw(Test::Class);
use Test::More tests => 2;

my $stderr;

BEGIN {
	$stderr = IO::File->new_tmpfile or die "no tmp file ($!)\n";
	*STDERR = $stderr;
};


my $sub = sub : Test(1) {print "ok\n"};
sub foo : Test(foo) {print "ok\n"};


END {
	seek $stderr, SEEK_SET, 0;
	like(<$stderr>, qr/cannot test anonymous subs/, 
			"cannot test anon sub");
	is(<$stderr>, "bad test definition 'foo' in main->foo\n",
			"bad number detected");
};
