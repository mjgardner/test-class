#! /usr/bin/perl -w

use Fcntl;
use IO::File;
use Test::Builder;

sub pass_all (&@) {
	my ($sub, $name) = @_;

	Test::Builder->no_ending(1);	# since we mess with current_test too much
	my $builder = Test::Builder->new;

	my $old_test = $builder->current_test;
	my $io = IO::File->new_tmpfile or die "bad tmp file ($!)";
	my ($output, $failure_out) = ($builder->output, $builder->failure_output);

	eval {
		$builder->output($io); 
		$builder->failure_output($io);
		$sub->();
	};
	
	my $exception = $@;
	my $failed = grep {$_ == 0} ($builder->summary)[$old_test .. $builder->current_test-1];
	$builder->output($output);
	$builder->failure_output($failure_out);
	$builder->current_test($old_test);
	die $exception if $exception;
	
	$builder->ok(!$failed, $name);
	if ($failed) {
		seek $io, SEEK_SET, 0;
		while (<$io>) { 
			next if m/^#\s+Failed test (.*?at line \d+)/;
			chomp;
			s/^((not )?ok)\s+\d+/$1/;
			s/^# //;
			$builder->diag("    $_") 
		};
	};
};


use Test::More 'no_plan';

pass_all {
	ok(1==1, "1==1");
	ok(2==2, "2==2");
} 'all ok';

pass_all {
	ok(1==2, "1==2");
	ok(2==1, "2==1");
} 'two failures';

