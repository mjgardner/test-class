package Discuss::Post;
use base qw(Discuss::Base);

use strict;
use warnings;
use Discuss::User;
use Discuss::Topic;
use Discuss::Exceptions qw(throw_banned_user throw_cannot_post);

our $VERSION = '0.10';

sub table		{ 'posts' };
sub columns		{ [ qw( post_id topic_id content user_id date) ] };
sub required	{ [ qw( topic_id content user_id ) ] };
sub default		{ [ date => sub { time } ] };

sub _increment_database_num_posts {
	my $self = shift;
	$$self->{dbh}->prepare_cached(
		"UPDATE boards SET num_posts=num_posts+1 where board_id = ?"
	)->execute($self->topic->board_id);
	$$self->{dbh}->prepare_cached(
		"UPDATE topics SET num_posts=num_posts+1 where topic_id = ?"
	)->execute($self->topic->topic_id);
};


sub new {
	my $class = shift;
	my %param = @_;
	my ($dbh, $user_id) = map {$param{$_}} (qw(dbh user_id));
	my $self;
	eval {
		$dbh->begin_work;
		$self = $class->SUPER::new(@_);
		throw_banned_user $self->user->user_id if $self->user->banned;
		throw_cannot_post $self->topic->topic_id
			unless $self->topic->can_post;
		_increment_database_num_posts($self);
		$dbh->commit;
		$self->topic->num_posts++;
		$self->topic->board->num_posts++;
	}; if ($@) {
		$dbh->rollback;
		die $@;
	};
	return($self);
};

sub user {
	my $self = shift;
	$$self->{user} ||= Discuss::User->fetch(
		dbh => $$self->{dbh}, user_id => $self->user_id
	);
};

sub topic {
	my $self = shift;
	$$self->{topic} ||= Discuss::Topic->fetch(
		dbh => $$self->{dbh}, topic_id => $self->topic_id
	);
};

1;
