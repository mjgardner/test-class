package Discuss::Topic;
use base qw(Discuss::Base);

use strict;
use warnings;

our $VERSION = '0.11';

sub table		{ 'topics' };
sub columns		{ [ qw( topic_id board_id name num_posts ) ] };
sub required	{ [ qw( board_id name ) ] };
sub default		{ [ num_posts => 0 ] };

sub num_posts : lvalue	{ ${+shift}->{num_posts} };	

sub board {
	my $self = shift;
	$$self->{board} ||= Discuss::Board->fetch(
		dbh => $$self->{dbh}, board_id => $self->board_id
	);
};

sub can_post {
	my $self = shift;
	my $b = $self->board;
	$b->can_post && ($b->type ne 'noreply' || !$self->num_posts);
};

1;
