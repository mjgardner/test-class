package Discuss::Tables;
use strict;
use warnings;
use base qw(Exporter);
use DBI;
use Discuss::Carp;

our $VERSION = '0.11';

our @EXPORT_OK = qw(create_table drop_table clear_table list_tables
	clear_all_tables );

my %Create_table = (
	boards => qq{
        CREATE TABLE boards (
            board_id SMALLINT UNSIGNED NOT NULL auto_increment,
            name VARCHAR(80) NOT NULL,
            num_posts MEDIUMINT DEFAULT '0' NOT NULL,
            status ENUM('hidden','live') DEFAULT 'hidden' NOT NULL,
            type ENUM('normal','static','noreply')   DEFAULT 'normal' NOT NULL,
            description TEXT DEFAULT '' NOT NULL,
            link TEXT DEFAULT '' NOT NULL,
            INDEX(num_posts),
            UNIQUE(name),
            PRIMARY KEY(board_id)
        ) TYPE = InnoDB
	},
	topics => qq{
		CREATE TABLE topics (
			topic_id MEDIUMINT UNSIGNED NOT NULL auto_increment,
			board_id SMALLINT UNSIGNED NOT NULL,
			name VARCHAR(80) NOT NULL,
			num_posts MEDIUMINT DEFAULT '0' NOT NULL,
			INDEX(num_posts),
			INDEX(board_id),
			INDEX(name),
			PRIMARY KEY(topic_id)
		) TYPE = InnoDB
	},
	posts => qq{
		CREATE TABLE posts (
			post_id INT UNSIGNED NOT NULL auto_increment,
			topic_id MEDIUMINT UNSIGNED NOT NULL,
			content TEXT NOT NULL,
			user_id INT UNSIGNED NOT NULL,
			date INT UNSIGNED NOT NULL,
			INDEX(topic_id),
			INDEX(date),
			PRIMARY KEY(post_id)
		) TYPE = InnoDB
	},
	users => qq{
		CREATE TABLE users (
			user_id INT UNSIGNED NOT NULL auto_increment,
			email VARCHAR(80) NOT NULL,
			name VARCHAR(80) NOT NULL,
			password VARCHAR(80) NOT NULL,
			banned TINYINT DEFAULT 0 NOT NULL,
			UNIQUE (name),
			UNIQUE (email),
			INDEX (name),
			INDEX(email),
			PRIMARY KEY(user_id)
		) TYPE = InnoDB
	},
);

sub list_tables { sort keys %Create_table };

sub _check_args {
	my ($dbh, @tables) = @_;
	confess "need dbh" unless UNIVERSAL::isa($dbh, 'DBI::db');
	foreach (@tables) {
		confess "unknown table $_" unless exists $Create_table{$_}
	};
	return($dbh, @tables);
};

sub drop_table {
	my ($dbh, @tables) = _check_args(@_);
	$dbh->do( "drop table $_" ) foreach @tables;
};

sub create_table {
	my ($dbh, @tables) = _check_args(@_);
	$dbh->do( $Create_table{$_} ) foreach @tables;
};

sub clear_table {
	my ($dbh, @tables) = _check_args(@_);
	eval { drop_table($dbh, $_) } foreach @tables;
	create_table($dbh, @tables);
};

sub clear_all_tables { clear_table( @_, list_tables() ) };

1;
