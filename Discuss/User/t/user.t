#! /usr/bin/perl 

use strict;
use warnings;

use strict;
use warnings;
use Test::More 'no_plan';
use Discuss::Tables qw(clear_table);
use Discuss::DBI;
use Test::DBI;
use Test::Exception;
use Discuss::Topic;

BEGIN { use_ok 'Discuss::User' };

my $dbh = Discuss::DBI->connect;
my $table = Discuss::User->table;

clear_table($dbh, $table);

isa_ok(
	my $b1 = Discuss::User->new(
		dbh => $dbh, email => 'email@foo.com', name => 'name', password => 'password'
	), 
	'Discuss::User'
);
row_count_is($dbh, $table, 1, 'row added for new user');
is $b1->user_id, 1, 'id found';
is $b1->name, 'name', 'name set';
is $b1->email, 'email@foo.com', 'email set';
is $b1->banned, 0, 'banned default';

isa_ok(
	my $b2 = Discuss::User->new(
		dbh => $dbh, email => 'email2@foo.com', name => 'name2', password => 'password', banned => 1,
	), 
	'Discuss::User'
);
row_count_is($dbh, $table, 2, 'second row added for new user');
is $b2->banned, 1, 'banned set';

throws_ok {
	Discuss::User->new(
		dbh => $dbh, email => 'email2@foo.com', name => 'name3', password => 'password', banned => 1,
	);
} 'Discuss::Exception::Duplicate', 'duplicate email detected';
row_count_is($dbh, $table, 2, 'no row added after duplicate email');

throws_ok {
	Discuss::User->new(
		dbh => $dbh, email => '//', name => 'name3', password => 'password', banned => 1,
	);
} 'Discuss::Exception::InvalidEmail', 'illegal email detected';
row_count_is($dbh, $table, 2, 'no row added after illegal email');

throws_ok {
	Discuss::User->new(
		dbh => $dbh, email => 'email3@foo.com', name => 'name2', password => 'password', banned => 1,
	);
} 'Discuss::Exception::Duplicate', 'duplicate name detected';
row_count_is($dbh, $table, 2, 'no row added after duplicate name');

dies_ok {
	Discuss::User->new(
		dbh => $dbh, name => 'name3', password => 'password', banned => 1,
	);
} 'missing email detected';
row_count_is($dbh, $table, 2, 'no row added after missing email');

dies_ok {
	Discuss::User->new(
		dbh => $dbh, email => 'email3@foo.com', password => 'password', banned => 1,
	);
} 'missing name detected';
row_count_is($dbh, $table, 2, 'no row added after missing name');

dies_ok {
	Discuss::User->new(
		dbh => $dbh, email => 'email3@foo.com', name => 'name3', banned => 1,
	); 
} 'missing password detected';
row_count_is($dbh, $table, 2, 'no row added after missing password');

