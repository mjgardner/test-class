#! /usr/bin/perl

# http://www.xprogramming.com/xpmag/acsBowling.htm

use strict;
use warnings;

package BowlingGame;

sub new {
	my $class = shift;
	bless { 
		score => 0,
		frame => 0,	
		additional_frames => 0,
	}, $class;
};

sub add_to_score {
	my ($self, $increment, $additional_frames) = @_;
	$self->{frame}++;
	$self->{score} += $increment;
	$self->{additional_frames} = $additional_frames;
};

sub spare {
	my $self = shift;
	$self->add_to_score(10, 1);
};

sub strike {
	my $self = shift;
	$self->add_to_score(10, 2);
};

sub open {
	my ($self, $num_pins) = @_;
	$self->{frame}++;
	$self->{score} += $num_pins if $self->{frame} <= 10;
	if ($self->{additional_frames}) {
		$self->{score} += $num_pins;
		$self->{additional_frames}--;
	};
};

sub score { 
	my $self = shift;
	$self->{score}
};


package BowlingGame::Test;
use base qw(Test::Class);
use Test::More 'no_plan';

sub make_new_game : Test(setup) {
	my $self = shift;
	$self->{new_game} = BowlingGame->new();
};

sub can_make_new_game : Test {
	my $self = shift;
	isa_ok $self->{new_game}, 'BowlingGame';
};

sub test_game {
	my $self = shift;
	my ($pins_down_per_game, $expected_score, $name) = @_;
	my $game = $self->{new_game};
	$game->open($pins_down_per_game) foreach (1..10);
	is $game->score, $expected_score, $name;
};

sub ten_gutter_balls : Test {
	my $self = shift;
	$self->test_game(0, 0, 'ten gutter balls score nothing');
};

sub ten_single_pins : Test {
	my $self = shift;
	$self->test_game(1, 10, 'ten single pins == 10');
};

sub spare_then_gutter : Test {
	my $self = shift;
	my $game = $self->{new_game};
	$game->spare;
	$game->open(0) foreach (1..9);
	is $game->score, 10, 'spare then gutter scores 10';
};

sub spare_then_one_pin : Test {
	my $self = shift;
	my $game = $self->{new_game};
	$game->spare;
	$game->open(1) foreach (1..9);
	is $game->score, 11+9, 'spare then 1 pin scores 11';
};

sub strike : Test {
	my $self = shift;
	my $game = $self->{new_game};
	$game->strike;
	$game->open(1) foreach (1..9);
	is $game->score, 12+9, 'strike then 1 pin x 2 scores 12';	
};

sub spare_at_end : Test {
	my $self = shift;
	my $game = $self->{new_game};
	$game->open(1) foreach (1..9);
	$game->spare;
	$game->open(1);
	is $game->score, 9 + 10+1, 'spare at end';
};

sub strike_at_end : Test {
	my $self = shift;
	my $game = $self->{new_game};
	$game->open(1) foreach (1..9);
	$game->strike;
	$game->open(1);
	$game->open(1);
	is $game->score, 9 + 10+1+1, 'strike at end';
};

sub strike_at_end_then_two_strikes : Test {
	my $self = shift;
	my $game = $self->{new_game};
	$game->open(1) foreach (1..9);
	$game->strike;
	$game->strike;
	$game->strike;
	is $game->score, 9 + 10+10+10, 'strike at end';
};
	
BowlingGame::Test->runtests;
