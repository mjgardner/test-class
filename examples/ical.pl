#! /usr/bin/perl -w

# This is a re-write of the example test script in Test::Tutorial
# into Test::Class idiom.

use strict;

package Date::ICal::Test;
use base qw(Test::Class);
use Date::ICal;
use Test::More;

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	my $test_dates = {
		'19971024T120000' => [ 1997, 10, 24, 12,  0,  0 ],
		'20390123T232832' => [ 2039,  1, 23, 23, 28, 32 ],
		'19671225T000000' => [ 1967, 12, 25,  0,  0,  0 ],
		'18990505T232323' => [ 1899,  5,  5, 23, 23, 23 ],
	};
	$self->{test_dates} = $test_dates;
	my $num_dates = keys %$test_dates;
	my $num_tests = $self->num_method_tests('test_dates');
	$self->num_method_tests("test_dates", $num_dates * $num_tests);
	return($self);
};

sub object : Test(setup) {
	my $self = shift;
	$self->{ical} = Date::ICal->new(
		year => 1964, month => 10, day => 16, 
		hour => 16, min => 12, sec => 47,
		tz => '0530', offset => 0
	);
};

sub _setup_worked : Test {
	my $self = shift;
	isa_ok($self->{ical}, 'Date::ICal')
			or $self->FAIL_ALL('no object to test');
};

sub check_fields : Test(6) {
	my $self = shift;
	is( $self->{ical}->sec,     47,     '  sec()'   );
	is( $self->{ical}->min,     12,     '  min()'   );
	is( $self->{ical}->hour,    16,     '  hour()'  );
	is( $self->{ical}->day,     16,     '  day()'   );
	is( $self->{ical}->month,	10,     '  month()' );
	is( $self->{ical}->year,	1964,	'  year()'  );
};

sub test_dates : Test(7) {
	my $self = shift;
	while( my($ical_str, $expect) = each %{$self->{test_dates}} ) {
	   my $ical = Date::ICal->new( ical => $ical_str, offset => 0 );
	   isa_ok($ical, 'Date::ICal');
	   is( $ical->year,    	$expect->[0],   '  year()'  );
	   is( $ical->month,	$expect->[1],   '  month()' );
	   is( $ical->day,     	$expect->[2],   '  day()'   );
	   is( $ical->hour,    	$expect->[3],   '  hour()'  );
	   is( $ical->min,     	$expect->[4],   '  min()'   );
	   is( $ical->sec,     	$expect->[5],	'  sec()'   );
	}
};

sub epoch_to_ical : Test(7) {
	return('epoch to ICal not working on MacOS') if $^O eq 'MacOS';
	my $t1 = Date::ICal->new( epoch => 0 );
	is( $t1->epoch, 0,          "Epoch time of 0" );
	is( $t1->ical, '19700101Z', "  epoch to ical" );
	is( $t1->year,  1970,       "  year()"  );
	is( $t1->month, 1,          "  month()" );
	is( $t1->day,   1,          "  day()"   );
	
	my $t2 = Date::ICal->new( ical => '19700101Z' );
	is( $t2->ical, '19700101Z', "Start of epoch in ICal notation" );
	is( $t2->epoch, 0,          "  and back to ICal" );
}


sub set_ical : Test {
	my $self = shift;
	local $TODO = 'ical not yet implemented';
	$self->{ical}->ical('20201231Z');
	is( $self->{ical}->ical, '20201231Z',   'Setting via ical()' );
}



package main;
Date::ICal::Test->runtests();
