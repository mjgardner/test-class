package Discuss::DBI;
use strict;
use warnings;
use DBI;
use Discuss::Exceptions qw(throw_dbi throw_duplicate);

our $VERSION = '0.08';

my $Class_dbh;

sub connect {
	$Class_dbh ||= DBI->connect(undef, undef, undef, {
		RaiseError			=> 1,
		AutoCommit			=> 1,
		PrintError			=> 0,
		Warn				=> 1,
		ShowErrorStatement	=> 1,
		FetchHashKeyName	=> 'NAME_lc',
		ChopBlanks			=> 1,
		LongTruncOk			=> 0,
		HandleError			=> sub {
			throw_duplicate $DBI::errstr
				if $DBI::errstr =~ m/duplicate/i;
			throw_dbi $DBI::errstr;
		},
	});
};

1;