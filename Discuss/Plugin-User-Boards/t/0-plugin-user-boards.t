#! /usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Apache::FakeRequest;
use Discuss::Board;
use Discuss::Topic;
use Discuss::Post;
use Discuss::User;
use Discuss::Tables qw(clear_all_tables);
use Scalar::Util qw(refaddr);
use Test::Exception;
use Template::Context;
use Discuss::DBI;

my $dbh = Discuss::DBI->connect;
clear_all_tables($dbh);

my $user = Discuss::User->new(name => 'test', email => 'email@foo.com',
	password => 'foo', dbh => $dbh);

my $b1 = Discuss::Board->new(dbh => $dbh, name => 'b1', 
		status => 'live', num_posts=>1);
my $b2 = Discuss::Board->new(dbh => $dbh, name => 'b2', 
		status => 'live', num_posts=>30);
my $b3 = Discuss::Board->new(dbh => $dbh, name => 'b3', 
		status => 'live', num_posts=>7);
my $b4 = Discuss::Board->new(dbh => $dbh, name => 'b4', 
		status => 'hidden');

my $b1t1 = Discuss::Topic->new(dbh => $dbh, name => 'b1t1', 
		board_id => $b1->board_id);
my $b1t2 = Discuss::Topic->new(dbh => $dbh, name => 'b1t2', 
		board_id => $b1->board_id);
my $b2t1 = Discuss::Topic->new(dbh => $dbh, name => 'b2t1', 
		board_id => $b2->board_id);
my $b4t1 = Discuss::Topic->new(dbh => $dbh, name => 'b4t1', 
		board_id => $b4->board_id);

my $b1t1p1 = Discuss::Post->new( dbh => $dbh, content => 'b1t1p1', 
		topic_id => $b1t1->topic_id, user_id => $user->user_id );
my $b1t1p2 = Discuss::Post->new( dbh => $dbh, content => 'b1t1p2', 
		topic_id => $b1t1->topic_id, user_id => $user->user_id, );
my $b1t2p1 = Discuss::Post->new( dbh => $dbh, content => 'b1t2p1', 
		topic_id => $b1t2->topic_id, user_id => $user->user_id, );
my $b2t1p1 = Discuss::Post->new( dbh => $dbh, content => 'b2t1p1', 
		topic_id => $b2t1->topic_id, user_id => $user->user_id, );

my $class;
BEGIN {
	$class = 'Discuss::Plugin::User::Boards';
	use_ok ( $class );
};

my $r = Apache::FakeRequest->new( uri => 'http://localhost/board/' );
my $context = Template::Context->new( VARIABLES => { _request => $r } );
isa_ok(my $o1 = Discuss::Plugin::User::Boards->new($context), $class);

is $o1->page_size, 10, 'default page size';
is $o1->max_page_size, 100, 'default max page size';
$o1->max_page_size(50);
is $o1->max_page_size, 50, 'max page size set';
$o1->page_size(3);
is $o1->page_size, 3, 'page size set';	
$o1->page_size(99);
is $o1->page_size, 3, 'cannot exceed max page size';
$o1->page_size(50);
is $o1->page_size, 50, 'can match max page size';
$o1->page_size('foo');
is $o1->page_size, 50, 'cannot set illegal size';

{
	my @boards = map {$_->name} @{$o1->by_name->as_list};
	is_deeply( \@boards, [qw(b1 b2 b3)], 'by_name' );
}

{
	my @boards = map {$_->name} @{$o1->by_name(2)->as_list};
	is_deeply( \@boards, [qw(b1 b2)], 'by_name limited' );
}

{
	my @boards = map {$_->name} @{$o1->most_recent->as_list};
	is_deeply( \@boards, [qw(b3 b2 b1)], 'most_recent' );
}

{
	my @boards = map {$_->name} @{$o1->most_recent(2)->as_list};
	is_deeply( \@boards, [qw(b3 b2)], 'most_recent limited' );
}

{
	my @boards = map {$_->name} @{$o1->most_popular->as_list};
	is_deeply( \@boards, [qw(b2 b3 b1)], 'most_popular' );
}

{
	my @boards = map {$_->name} @{$o1->most_popular(2)->as_list};
	is_deeply( \@boards, [qw(b2 b3)], 'most_popular limited' );
}

ok !$o1->current_board, 'current_board with nothing';
ok !$o1->current_topic, 'current_topic with nothing';

$r->{uri} = 'http://localhost/board/' . $b4->board_id . '/topic/' 
		. $b4t1->topic_id;
$o1 = Discuss::Plugin::User::Boards->new($context);

throws_ok { $o1->current_board } 'Discuss::Exception::BoardNotLive', 
	'current_board with inactive board';
throws_ok { $o1->current_topic } 'Discuss::Exception::BoardNotLive', 
	'current_topic with inactive board';

$r->{uri} = 'http://localhost/board/' . $b1->board_id . '/topic/' 
		. $b1t1->topic_id . '/post/' . $b1t1p1->post_id;
$o1 = Discuss::Plugin::User::Boards->new($context);

is $o1->current_board->name, $b1->name, 'current_board with board/topic/post';
is $o1->current_topic->name, $b1t1->name, 'current_topic with board/topic/post';

$r->{uri} = 'http://localhost/board/' . $b1->board_id . '/topic/' 
		. $b1t1->topic_id . '/post/' . $b2t1p1->post_id;
$o1 = Discuss::Plugin::User::Boards->new($context);

$r->{uri} = 'http://localhost/board/' . $b1->board_id;
$o1 = Discuss::Plugin::User::Boards->new($context);

is $o1->current_board->name, $b1->name, 'current_board with board';
ok !$o1->current_topic, 'current_topic with board';

$r->{uri} = 'http://localhost/topic/' . $b1t1->topic_id;
$o1 = Discuss::Plugin::User::Boards->new($context);

is $o1->current_board->name, $b1->name, 'current_board with topic';
is $o1->current_topic->name, $b1t1->name, 'current_topic with topic';
