#! /usr/bin/perl -w

BEGIN {

	use strict;
	use Test::Builder;
	use File::Find;
	use File::Spec;
	use FindBin;

	my $Test = Test::Builder->new;
	
	eval 'use Pod::Checker';
	$Test->skip_all("need Pod::Checker") if $@;
	
	eval 'use IO::String';
	$Test->skip_all("need IO::String") if $@;
	
	my $Blib = File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'blib', 'lib');
	$Test->skip_all("no $Blib directory") unless -d $Blib;
	
	my @Module_files = ();
	find(sub {(push @Module_files, $File::Find::name) if $_ =~ m/\.(pm|pod)$/}, $Blib);
	$Test->skip_all("no modules in $Blib") unless @Module_files;
	
	$Test->expected_tests(scalar(@Module_files));
	
	foreach my $module (sort @Module_files) {
		my $errors = IO::String->new;
		my $checker = Pod::Checker->new(-warnings => 1);
		$checker->parse_from_file($module, $errors);
		my @warnings = grep(
			# I should really fix Pod::Checker :-)
			!/(WARNING: node 'http:.*non-escaped)|(pod syntax OK)/, 
			split /\n/, ${$errors->string_ref}
		);
		my $ok = $checker->num_errors < 1 && !@warnings;
		$Test->ok($ok, "$module POD legal") || $Test->diag(@warnings);
	};

};
