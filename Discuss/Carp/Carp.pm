package Discuss::Carp;
use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '0.01';
our @EXPORT = qw(confess carp croak);

sub carp {
	my $level = 1;
	my $stack_trace = "@_";
	$stack_trace .= "\n" unless $stack_trace =~ m/\n$/;
	while ( my ($filename, $line, $sub) = (caller($level++))[1..3] ) {	
		$stack_trace .= "$sub, $filename line $line\n";
	};
	die $stack_trace;
};

*croak = \&carp;
*confess = \&carp;

1;