# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
$|=1;
use Test::More 'no_plan';
BEGIN { use_ok('SVN::Backup') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use File::Spec;
use File::Find;
use Test::Exception;
use File::Path qw(mkpath);
use constant VERBOSE => $ENV{TEST_VERBOSE};

my @Directories_to_delete;
sub tmp_path {
	my $name = shift;
	my $path = File::Spec->catfile( File::Spec->tmpdir, "$name.$$" );
	die "$path already exists" if -e $path;
	push @Directories_to_delete, $path;
	return $path;
};	

sub update_test_directory {
	my ($dir, $min, $max)=@_;
	diag "creating test import directory $dir" if VERBOSE && ! -e $dir;
	mkpath($dir);
	foreach ($min..$max) {
		open my $fh, ">", File::Spec->catfile($dir, $_) or die "$!";
		print $fh rand(9999),"\n";
	};
};

sub update_repository {
	my $checkout_dir = shift;
	diag "updating repository" if VERBOSE;
	update_test_directory($checkout_dir, 1,10);
	system('svn', 'commit', '--quiet', '-m', 'test', $checkout_dir ) == 0 
		or die "could not commit test directory ($?)\n";
};

my $repository = tmp_path("svn");
my $backup_dir = tmp_path("svn.bak");
my $import_dir = tmp_path("svn.import");
my $checkout_dir = tmp_path("svn.checkout");

update_test_directory($import_dir, 1,10);

dies_ok { SVN::Backup->new(
	repository => $repository,
	root => $backup_dir
) } 'cannot use non-existant repository';

diag "creating test repository $repository" if VERBOSE;
system('svnadmin', 'create', $repository) == 0 
	or die "could not create test repository $repository ($?)\n";
	
isa_ok my $o = SVN::Backup->new(
	repository => $repository,
	root => $backup_dir
), 'SVN::Backup';

is $o->repository_revision, 0, 'repository revision is zero';

ok( -d $backup_dir, 'backup directory created');

ok( ! $o->is_current, 'repository not current before backup' );

lives_ok { $o->backup } 'backup made';

ok( $o->is_current, 'repository is current after backup' );

diag "importing test directory to test repository" if VERBOSE;
system('svn', 'import', '--quiet', '-m', 'test', $import_dir, "file://$repository") == 0 
	or die "could not import test directory ($?)\n";

ok( !$o->is_current, 'repository is not current after repository update' );

diag "checking out test repository" if VERBOSE;
system('svn', 'co', '--quiet', "file://$repository", $checkout_dir) == 0 
	or die "could not checkout test repository ($?)\n";
update_repository($checkout_dir);
	
lives_ok { $o->backup } 'new backup made';
ok( $o->is_current, 'repository current after new backup' );

update_repository($checkout_dir);
lives_ok { $o->backup } 'new backup made';
is $o->repository_revision, 3, 'repository revision updated';


END {
	diag "removing test directories"
		if VERBOSE;
	find( {
		wanted => sub {
			my $path = $File::Find::name;
			my $deleted_ok = -d $path ? rmdir $path : unlink $path;
			warn "warning: could not remome $path ($!)\n" 
				unless $deleted_ok;
		},
		bydepth => 1,
	}, map {-d $_ ? $_ : () } @Directories_to_delete ); 
};