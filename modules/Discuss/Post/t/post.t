#! /usr/bin/perl 

use strict;
use warnings;
use diagnostics;
use Test::More 'no_plan';
use Discuss::Tables qw(clear_all_tables);
use Discuss::DBI;
use Test::DBI;
use Test::Exception;
use Discuss::Topic;
use Discuss::User;
use Discuss::Board;

BEGIN { use_ok('Discuss::Post') };

my $dbh = Discuss::DBI->connect;
my $table = Discuss::Post->table;

clear_all_tables($dbh);

my $user = Discuss::User->new(
	dbh => $dbh,
	name => 'name', password => 'password', email => 'email@foo.com'
);

my $banned_user = Discuss::User->new(
	dbh => $dbh,
	name => 'banned', password => 'password', email => 'banned@foo.com',
	banned => 1,
);

my $topic = Discuss::Topic->new(
	dbh => $dbh,
	name => 'topic', board_id=>1
);

my $board = Discuss::Board->new(
	dbh => $dbh,
	name => 'board', status=>'live',
);

my $t1 = time;
isa_ok(my $post = Discuss::Post->new(
	dbh => $dbh, 
	topic_id => $topic->topic_id, 
	content => 'content', 
	user_id => $user->user_id,
), 'Discuss::Post', 't1');
row_count_is($dbh, $table, 1);
my $t2 = time;

is $post->post_id, 1, 'post_id set';
is $post->topic_id, $topic->topic_id, 'topic_id set';
is $post->content, 'content', 'content set';
is $post->user_id, $user->user_id, 'user_id set';
ok $post->date >= $t1, 'date after start time';
ok $post->date <= $t2, 'date before end time';

is $post->topic->name, $topic->name, 'topic fetched';
is $post->user->name, $user->name, 'user fetched';
is(Discuss::Topic->pool_size, 1, 'topics pooled');
is(Discuss::User->pool_size, 2, 'users pooled');

is $topic->num_posts, 1, 'direct in-memory topic num_posts updated';
is $post->topic->num_posts, 1, 'indirect in-memory topic num_posts updated';
is $board->num_posts, 1, 'direct in-memory board num_posts updated';
is $post->topic->board->num_posts, 1, 'indirect in-memory board num_posts updated';

select_ok(
	$dbh, 
	'select board_id from boards where board_id=1 and num_posts=1',
	1,
	'database board num_posts updated'
);

select_ok(
	$dbh, 
	'select topic_id from topics where topic_id=1 and num_posts=1',
	1,
	'database topic num_posts updated'
);

{

	my $board = Discuss::Board->new(
		dbh => $dbh,
		name => 'board2', status=>'hidden',
	);
	
	my $topic = Discuss::Topic->new(
		dbh => $dbh,
		name => 'topic', board_id=>$board->board_id,
	);
	
	throws_ok { Discuss::Post->new(
		dbh => $dbh, 
		topic_id => $topic->topic_id, 
		content => 'content', 
		user_id => $user->user_id,
	) } 'Discuss::Exception::CannotPost';

};

{
	no warnings;
	local *DBI::db::commit = sub { die "commit failed\n" };
	use warnings;
	dies_ok { Discuss::Post->new(
		dbh => $dbh, 
		topic_id => $topic->topic_id, 
		content => 'content', 
		user_id => $user->user_id,
	) } 'bad post detected';
}

is $topic->num_posts, 1, 'direct in-memory topic num_posts unchanged';
is $board->num_posts, 1, 'direct in-memory board num_posts unchanged';

select_ok(
	$dbh, 
	'select board_id from boards where board_id=1 and num_posts=1',
	1,
	'database board num_posts unchanged'
);

select_ok(
	$dbh, 
	'select topic_id from topics where topic_id=1 and num_posts=1',
	1,
	'database topic num_posts unchanged'
);

dies_ok { Discuss::Post->new(
	dbh => $dbh, 
	topic_id => $topic->topic_id, 
	content => 'content', 
	user_id => $banned_user->user_id,
) } 'banned users cannot post';

dies_ok { Discuss::Post->new(
	dbh => $dbh, 
	topic_id => $topic->topic_id, 
	content => 'content', 
	user_id => 9999,
) } 'must supply a valid user';

dies_ok { Discuss::Post->new(
	dbh => $dbh, 
	topic_id => $topic->topic_id, 
	content => 'content', 
) } 'must supply a user';

