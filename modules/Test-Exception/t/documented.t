#! /usr/bin/perl -w

BEGIN {

	use strict;
	use Test::Builder;
	use File::Find;
	use File::Spec;
	use FindBin;
	
	my $Test = Test::Builder->new;
	
	eval 'use Pod::Coverage';
	$Test->skip_all("need Pod::Coverage") if $@;
	
	my $Blib = File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'blib', 'lib');
	$Test->skip_all("no $Blib directory") unless -d $Blib;
	
	my %Filename_of_module = ();
	find( 
		sub {
			return unless $_ =~ m/\.pm$/;
			my $module = $File::Find::name;
			$module =~ s/\.pm$//s;
			$module =~ s/^\Q$File::Find::topdir\E//s;
			$module = join('::', grep !/^$/, File::Spec->splitdir($module));
			$Filename_of_module{$module} = $File::Find::name;
		}, $Blib
	);
	$Test->skip_all("no modules in $Blib") unless %Filename_of_module;
	
	$Test->no_plan;
		
	foreach my $module (sort keys %Filename_of_module) {
		my $file = $Filename_of_module{$module};
		my $pc = new Pod::Coverage(package => $module, pod_from => $file);
		my $coverage = $pc->coverage;
		if (defined($coverage)) {
			$Test->ok(1, "$module->$_ documented") foreach sort $pc->covered;
			$Test->ok(0, "$module->$_ documented") foreach sort $pc->uncovered;
			$Test->diag("$module undocumented: ". join(', ', $pc->uncovered)) unless $coverage == 1;
		} else {
			$Test->ok(0, "$module unrated: ". $pc->why_unrated)
		};
	};

};
