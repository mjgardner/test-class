#! /usr/bin/perl

package Test::DBI;
use strict;
use warnings;
use DBI;
use Test::Builder;
use base qw(Exporter);

our $VERSION = '0.04';
our @EXPORT = qw( row_count_is table_absent table_exists select_ok );

my $Test = Test::Builder->new;

sub row_count_is {
	my ($dbh, $table, $expected, $name) = @_;
	$name ||= "found $expected row(s) in table $table";
	my ($got) = eval {$dbh->selectrow_array("select count(*) from $table")};
	if ($@ || $DBI::err) {
		$Test->ok(0, $name);
		$Test->diag($DBI::errstr);
	} else {
		$Test->is_num($got, $expected, $name);
	};
};

sub _has_table {
	my ($dbh, $table) = @_;
	eval { $dbh->do("select count(*) from $table") };
	return(! ($@ || $DBI::err));
};

sub table_exists {
	my ($dbh, $table, $name) = @_;
	$name ||= "table $table exists";
	$Test->ok(_has_table($dbh, $table), $name);
};

sub table_absent {
	my ($dbh, $table, $name) = @_;
	$name ||= "table $table absent";
	$Test->ok(! _has_table($dbh, $table), $name);
};

sub select_ok {
	my ($dbh, $select, $expected_num_rows, $name) = @_;
	$name ||= "$expected_num_rows row(s) selected";
	my $num_rows = 0;
	eval {
		my $sth = $dbh->prepare($select);
		$sth->execute;
		while ($sth->fetch) {++$num_rows};
	};
	if ($@ || $DBI::err) {
		$Test->ok(0, $name);
		$Test->diag($DBI::errstr);
	} else {
		$Test->is_num($num_rows, $expected_num_rows, $name);	
	};
};

1;
