use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Test::Builder;
use Fcntl;
use IO::File;

my $io = IO::File->new_tmpfile or die "couldn't create tmp file ($!)\n";
my $Test = Test::Builder->new;
					
$Test->output($io);
$Test->failure_output($io);
Test::Class->SKIP_ALL("skipping");

END {
	seek $io, SEEK_SET, 0;
	print "1..1\n";
	my @output = <$io>;
	shift @output if $output[0] =~ /^TAP version \d+/; 
	my $ok = $output[0] =~ /^1..0 # Skip skipping$/i;
	print "not " unless $ok;
	print "ok 1 - SKIP_ALL called skip_all\n";
}
