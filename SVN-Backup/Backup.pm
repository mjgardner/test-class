package SVN::Backup;

use 5.006001;
use strict;
use warnings;
use Carp qw(croak);
use File::Path qw(mkpath);
use File::Find::Rule;
use List::Util qw(max);
use POSIX qw(strftime);

our $VERSION = '0.01';

sub new {
	my ($class, %param) = @_;
	my ($repository, $root) = map {
		exists $param{$_} ? $param{$_} : croak "need $_\n";
	} qw(repository root);
	croak "$repository does not exist" unless -e $repository;
	mkpath($root) unless -e $root;
	bless {
		repository => $repository,
		root => $root,
	}, $class;
};

sub repository { shift->{repository} };
sub root { shift->{root} };

sub backup_revision {
	my $self = shift;
	my @revisions = map { $_ =~ m/r\d+-(\d+).dumpfile/ ? $1 : () }
		 File::Find::Rule->in($self->root);
	@revisions ? max(@revisions) : -1;
};

sub _output_of {
	my @command = @_;
	my $pid = open(my $fh, "-|");
	croak "cannot fork ($!)" unless defined($pid);
	if ($pid) {
		my $output;
		{
			local $/; 
			$output = <$fh>;
		}
		chomp $output;
		return $output;
	} else {
		exec(@command) || croak "cannot exec ($!)\n";
	};
};

sub repository_revision {
	my $self = shift;
	_output_of('svnlook', 'youngest', $self->repository);
};

sub is_current {
	my $self = shift;
	my $r = $self->repository_revision;
	my $b = $self->backup_revision;
	croak "backup older than repository!" if $b > $r;
	return $b == $r;
};

sub backup {
	my $self = shift;
	return if $self->is_current;
	my $from = $self->backup_revision+1;
	my $to = $self->repository_revision;
	my $date = strftime("%Y-%m-%d", localtime);
	my $path = File::Spec->catfile(
		$self->root, "$date-r$from-$to.dumpfile"
	);

	open my $oldout, ">&STDOUT" or croak "Can't dup STDOUT: $!";
	open STDOUT, '>', $path or croak "Can't redirect STDOUT: $!";
	$|=1;
	my $worked = system(
		'svnadmin', 'dump', $self->repository, 
		$from == 0 ? () : ('--incremental'), 
		'--quiet',
		'-r', "$from:$to"
	) == 0;
	close(STDOUT);
	open STDOUT, ">&", $oldout or croak "Can't dup \$oldout: $!";
	
	unless ($worked) {
		unlink $path;
		die "could not dump repository ($?)\n";
	};
};


1;
__END__

=head1 NAME

SVN::Backup - Simple incremental backup tool based on svnadmin dump

=head1 SYNOPSIS

  use SVN::Backup;
  
  my $o = SVN::Backup->new(
    repository => $repository_url,
    root => $directory_for_backups,
  );
  
  $o->backup;
  


=head1 ABSTRACT

Allows you to easily maintain a directory of incremental SVN dumps for backup purposes.

=head1 DESCRIPTION

Do what it says in the synopsis.

=head1 SEE ALSO

Other SVN:: modules in CPAN.

=head1 AUTHOR

Adrian Howard, E<lt>adrianh@quietstars.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Adrian Howard

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
