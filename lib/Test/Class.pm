#! /usr/bin/perl -Tw

package Test::Class;
use 5.006;
use strict;
use warnings;

use Attribute::Handlers;
use Carp;
use Class::ISA;
use Devel::Symdump;
use Storable qw(dclone);
use Test::Builder;
use Test::Class::MethodInfo;


our $VERSION = '0.07';


use constant NO_PLAN	=> "no_plan";
use constant SETUP		=> "setup";
use constant TEST		=> "test";
use constant TEARDOWN	=> "teardown";
use constant STARTUP	=> "startup";
use constant SHUTDOWN	=> "shutdown";


our	$Current_method	= undef;
sub current_method { $Current_method };


my $Builder = Test::Builder->new;
sub builder { $Builder };


my $Tests = {};


my %_Test;  # inside-out object field indexed on $self

sub DESTROY {
    my $self = shift;
    delete $_Test{$self};
};

sub _test_info {
	my $self = shift;
	return(ref($self) ? $_Test{$self} : $Tests);
};

sub _method_info {
	my ($self, $class, $method) = @_;
	return(_test_info($self)->{$class}->{$method});
};

sub _methods_of_class {
	my ($self, $class) = @_;
	return(values %{_test_info($self)->{$class}});
};

sub _parse_attribute_args {
    my $args = shift || '';
	my $num_tests;
	my $type;
	$args =~ s/\s+//sg;
	foreach my $arg (split /=>/, $args) {
		if (Test::Class::MethodInfo->is_num_tests($arg)) {
			$num_tests = $arg;
		} elsif (Test::Class::MethodInfo->is_method_type($arg)) {
			$type = $arg;
		} else {
			die 'bad attribute args';
		};
	};
	return( $type, $num_tests );
};

sub Test : ATTR(CODE,RAWDATA) {
	my ($class, $symbol, $code_ref, $attr, $args) = @_;
	if ($symbol eq "ANON") {
		warn "cannot test anonymous subs\n";
	} else {
        my $name = *{$symbol}{NAME};
        eval { 
            my ($type, $num_tests) = _parse_attribute_args($args);        
            $Tests->{$class}->{$name} = Test::Class::MethodInfo->new(
                name => $name, 
                num_tests => $num_tests,
                type => $type,
            );	
        } || warn "bad test definition '$args' in $class->$name\n";	
    };
};

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	$proto = {} unless ref($proto);
	my $self = bless {%$proto, @_}, $class;
	$_Test{$self} = dclone($Tests);
	return($self);
};

sub _get_methods {
	my ($self, @types) = @_;
	my $test_class = ref($self) || $self;
	my %methods = ();
	foreach my $class (Class::ISA::self_and_super_path($test_class)) {
		foreach my $info (_methods_of_class($self, $class)) {
			foreach my $type (@types) {
				$methods{$info->name} = 1 if $info->is_type($type);
			};
		};
	};
	return(sort keys %methods);
};

sub _num_expected_tests {
	my $self = shift;
	my @startup_shutdown_methods = 
			_get_methods($self, STARTUP, SHUTDOWN);
	my $num_startup_shutdown_methods = 
			_total_num_tests($self, @startup_shutdown_methods);
	return(NO_PLAN) if $num_startup_shutdown_methods eq NO_PLAN;
	my @fixture_methods = _get_methods($self, SETUP, TEARDOWN);
	my $num_fixture_tests = _total_num_tests($self, @fixture_methods);
	return(NO_PLAN) if $num_fixture_tests eq NO_PLAN;
	my @test_methods = _get_methods($self, TEST);
	my $num_tests = _total_num_tests($self, @test_methods);
	return(NO_PLAN) if $num_tests eq NO_PLAN;
	return($num_startup_shutdown_methods + $num_tests + @test_methods * $num_fixture_tests);
};

sub expected_tests {
	my $total = 0;
	foreach my $test (@_) {
		if (UNIVERSAL::isa($test, __PACKAGE__)) {
			my $n = _num_expected_tests($test);
			return(NO_PLAN) if $n eq NO_PLAN;
			$total += $n;
		} elsif ($test =~ m/^\d+$/) {
			# SHOULD ALSO ALLOW NO_PLAN
			$total += $test;
		} else {
			$test = 'undef' unless defined($test);
			croak "$test is not a Test::Class or an integer";
		};
	};
	return($total);
};

sub _total_num_tests {
	my ($self, @methods) = @_;
	my $class = ref($self) || $self;
	my $total_num_tests = 0;
	foreach my $method (@methods) {
		foreach my $class (Class::ISA::self_and_super_path($class)) {
			my $info = _method_info($self, $class, $method);
			next unless $info;
			my $num_tests = $info->num_tests;
			return(NO_PLAN) if ($num_tests eq NO_PLAN);
			$total_num_tests += $num_tests;
			last unless $num_tests =~ m/^\+/
		};
	};
	return($total_num_tests);
};

sub _all_ok_from {
	my ($self, $start_test) = @_;
	my $current_test = $Builder->current_test;
	return(1) if $start_test == $current_test;
	my @results = ($Builder->summary)[$start_test .. $current_test-1];
	foreach my $result (@results) { return(0) unless $result };
	return(1);
};

sub _exception_failure {
	my ($self, $method, $exception, $tests) = @_;
	local $Test::Builder::Level = 3;
	my $message = $method;
	$message .= " (for test method '$Current_method')"
			if $method ne $Current_method;
	_show_header($self, @$tests) unless $Builder->has_plan;
	$Builder->ok(0, "$message died ($exception)");
};

sub _run_method {
	my ($self, $method, $tests) = @_;
	my $original_ok = \&Test::Builder::ok;
	{
	    no warnings;
        *Test::Builder::ok = sub {
            my ($builder, $test, $name) = @_;
            local $Test::Builder::Level = $Test::Builder::Level+1;
            unless ( defined($name) ) {
                $name = $self->current_method;
                $name =~ tr/_/ /;
            };
            $original_ok->($builder, $test, $name)
        };
	};
	my $num_start = $Builder->current_test;
	my $skip_reason = eval {$self->$method};
	my $exception = $@;
	chomp($exception) if $exception;
	my $num_done = $Builder->current_test - $num_start;
	my $num_expected = _total_num_tests($self, $method);
	$num_expected = $num_done if $num_expected eq NO_PLAN;
	if ($num_done == $num_expected) {
		_exception_failure($self, $method, $exception, $tests) 
				unless $exception eq '';
	} elsif ($num_done > $num_expected) {
		$Builder->diag("expected $num_expected test(s) in $method, $num_done completed\n");
	} else {
		until (($Builder->current_test - $num_start) >= $num_expected) {
			if ($exception ne '') {
				_exception_failure($self, $method, $exception, $tests);
				$skip_reason = "$method died";
				$exception = '';
			} else {
				$Builder->skip($skip_reason || $method);
			};
		};
	};
	return(_all_ok_from($self, $num_start));
};

sub _show_header {
	my ($self, @tests) = @_;
	my $num_tests = Test::Class->expected_tests(@tests);
	if ($num_tests eq NO_PLAN) {
		$Builder->no_plan;
	} else {
		$Builder->expected_tests($num_tests);
	};
};

sub runtests {
	my @tests = @_;
	if (@tests == 1 && !ref($tests[0])) {
		my $base_class = shift @tests;
		@tests = $base_class->run_all_classes;
	};
	my $all_passed = 1;
	foreach my $t (@tests) {
		# SHOULD ALSO ALLOW NO_PLAN
		next if $t =~ m/^\d+$/;
		croak "$t not Test::Class or integer" 
				unless UNIVERSAL::isa($t, __PACKAGE__);
		$t = $t->new unless ref($t);
		my $class = ref($t);
		my @setup = _get_methods($t, SETUP);
		my @teardown = _get_methods($t, TEARDOWN);
		foreach my $method (_get_methods($t, STARTUP)) {
		    _show_header($t, @tests) 
					unless $Builder->has_plan 
					|| _total_num_tests($t, $method) eq '0';
			my $method_passed = _run_method($t, $method, \@tests);
			$all_passed &&= $method_passed;
		};
		foreach my $test (_get_methods($t, TEST)) { 
			local $Current_method = $test;
		   	$Builder->diag("\n$class->$test") if $ENV{TEST_VERBOSE};
			foreach my $method (@setup, $test, @teardown) {
				_show_header($t, @tests) 
						unless $Builder->has_plan 
						|| _total_num_tests($t, $method) eq '0';
				my $method_passed = _run_method($t, $method, \@tests);
				$all_passed &&= $method_passed;
			};
		};
		foreach my $method (_get_methods($t, SHUTDOWN)) {
			_show_header($t, @tests) 
					unless $Builder->has_plan 
					|| _total_num_tests($t, $method) eq '0';
			my $method_passed = _run_method($t, $method, \@tests);
			$all_passed &&= $method_passed;
		};

	};
	return($all_passed);
};

my %AUTORUN = ();

sub autorun {
	my $class = shift;
	$class = ref($class) if ref($class);
	$AUTORUN{$class} = shift if @_;
	return($AUTORUN{$class}) if defined($AUTORUN{$class});
	foreach (Devel::Symdump->rnew->packages) {
		return(0) if UNIVERSAL::isa($_, $class) && $class ne $_;
	};
	return(1);
};

sub run_all_classes {
	my $class = shift;
	grep {UNIVERSAL::isa($_, $class) && $_->autorun} 
			Devel::Symdump->rnew->packages;
};

sub _find_calling_test_class {
	my $level = 0;
	while (my $class = caller(++$level)) {
		next if $class eq __PACKAGE__;
		return($class) if $class->isa(__PACKAGE__);
	}; 
	return(undef);
};

sub num_method_tests {
	my ($self, $method, $n) = @_;
	my $class = _find_calling_test_class( $self )
	    or croak "not called in a Test::Class";
	my $info = _method_info($self, $class, $method)
	    or croak "$method is not a test method of class $class";
	$info->num_tests($n) if defined($n);
	return( $info->num_tests );
};

sub num_tests {
    my $self = shift;
	croak "num_tests need to be called within a test method"
			unless defined $Current_method;
	return( $self->num_method_tests( $Current_method, @_ ) );
};

sub BAILOUT {
	my ($self, $reason) = @_;
	$Builder->BAILOUT($reason);
};

sub _last_test_if_exiting_immediately {
    $Builder->expected_tests || $Builder->current_test+1
};

sub FAIL_ALL {
	my ($self, $reason) = @_;
	my $last_test = _last_test_if_exiting_immediately();
	$Builder->expected_tests( $last_test ) unless $Builder->has_plan;
	$Builder->ok(0, $reason) until $Builder->current_test >= $last_test;
	my $num_failed = grep( !$_, $Builder->summary );
	exit( $num_failed < 254 ? $num_failed : 254 );
};

sub SKIP_ALL {	
	my ($self, $reason) = @_;
	$Builder->skip_all( $reason ) unless $Builder->has_plan;
	my $last_test = _last_test_if_exiting_immediately();
	$Builder->skip( $reason ) 
	    until $Builder->current_test >= $last_test;
	exit(0);
}

1;
