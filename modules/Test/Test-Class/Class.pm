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

our $VERSION = '0.05';

our	$Current_method	= undef;
my	$Builder		= Test::Builder->new;

use constant NO_PLAN	=> "no_plan";
use constant SETUP		=> "setup";
use constant TEST		=> "test";
use constant TEARDOWN	=> "teardown";
use constant STARTUP	=> "startup";
use constant SHUTDOWN	=> "shutdown";


=head1 NAME

Test::Class - easily create test classes in an xUnit/JUnit style

=head1 SYNOPSIS

  sub new {
      my $class = shift;
      my $self = $class->SUPER::new(@_);
      my $n = $self->num_method_tests('test_method')
      $self->num_method_tests('test_method', 4)
      return($self);
  };

  sub test_method : Test(no_plan); {
      my $self = shift;
      my $n = $self->num_tests;
      $self->num_tests(3);
  };


  $Tests->BAILOUT($reason)
  $Tests->SKIP_ALL($reason)
  $Tests->FAIL_ALL($reason)

  my $expected = $Tests->expected_tests;

  my $all_ok = $Tests->runtests;


=head1 DESCRIPTION

Test::Class provides a simple way of creating classes and objects to test your code in an xUnit style. 

... insert summary of features here ...

Built using L<Test::Builder> it is designing to work with other Test::Builder based modules (L<Test::More>, L<Test::Differences>, L<Test::Exception>, etc.)  

I<Note:> This module will make more sense if you are already familiar with the "standard" mechanisms for testing perl code. Those unfamiliar  with L<Test::Harness>, L<Test::Simple>, L<Test::More> and friends should go take a look at them now. L<Test::Tutorial> is a good starting point.

L<Test::Class::Tutorial> attempts to provide a gentle introduction to the features of Test::Class.


=head1 A BRIEF EXAMPLE

A simple test class:

  package Example::Test;
  use base qw(Test::Class);
  use Test::More;

  # setup methods are run before every test method. 
  sub make_fixture : Test(setup) {
      my $array = [1, 2];
      shift->{test_array} = $array;
      diag("array = (@$array) before test(s)");
  };

  # a test method that runs 1 test
  sub test_push : Test {
      my $array = shift->{test_array};
      push @$array, 3;
      is_deeply($array, [1, 2, 3], 'push worked');
  };

  # a test method that runs 4 tests
  sub test_pop : Test(4) {
      my $array = shift->{test_array};
      is(pop @$array, 2, 'pop = 2');
      is(pop @$array, 1, 'pop = 1');
      is_deeply($array, [], 'array empty');
      is(pop @$array, undef, 'pop = undef');
  };

  # teardown methods are run after every test method.
  sub teardown : Test(teardown) {
      my $array = shift->{test_array};
      diag("array = (@$array) after test(s)");
  };

You run the tests like this:

  Example::Test->runtests;

An will get the following results:

  # array = (1 2) before test(s)
  1..5
  ok 1 - pop = 2
  ok 2 - pop = 1
  ok 3 - array empty
  ok 4 - pop = undef
  # array = () after test(s)
  # array = (1 2) before test(s)
  ok 5 - push worked
  # array = (1 2 3) after test(s)


=head1 INTRODUCTION


=head2 A brief history lesson

A long time ago (well in 1994) Kent Beck wrote a testing framework for Smalltalk called SUnit. It was popular. You can read a copy of his original paper at L<http://www.xprogramming.com/testfram.htm>.

Later Kent Beck and Erich Gamma created JUnit for testing Java L<http://www.junit.org/>. It was popular too.

Now there xUnit frameworks for every language from Ada to XSLT. You can find a list at L<http://www.xprogramming.com/software.htm>.

While xUnit frameworks are traditionally associated with unit testing they are also useful in the creation of functional/acceptance tests.

Test::Class is (yet another) implementation of xUnit style testing in perl. 


=head2 Why you should use Test::Class

Test::Class attempts to provide simple xUnit testing that integrates simply with the standard perl *.t style of testing. In particular:

=over 4

=item *

It is built with L<Test::Builder> and should co-exist happily with all other Test::Builder based modules. This makes using test classes in *.t scripts, and refactoring normal tests into test classes, much simpler because:

=over 4

=item *

Test::Class attempts to provide the minimum of new functionality necessary to support the creation of test classes.

=item *

You do not have to learn a new set of new test APIs and can continue using ok(), like(), etc. from L<Test::More> and friends. 

=item *

Skipping tests and todo tests are supported. 

=item *

You can have normal tests and Test::Class classes co-existing in the same *.t script. You don't have to re-write an entire script, but can use test classes as and when it proves useful.

=back

=item *

It provides a framework that should be familiar to people who have used other xUnit style test systems.

=item *

You can easily package your tests as classes/modules, rather than *.t scripts. This simplifies reuse and distribution, encourages refactoring, and allows tests to be extended by inheritance.

=item *

You can have multiple setup/teardown methods. This is surprisingly useful (e.g. have one teardown method to clean up resources and another to check that class invarients still hold).

=item *

It can make running tests faster. Once you have refactored your *.t scripts into classes they can be easily run from a single script. This gains you the (often considerable) startup time that each separate *.t script takes.

=back


=head2 Why you should I<not> use Test::Class

=over 4

=item *

If your *.t scripts are working fine then don't bother with Test::Class. For simple test suites it is almost certainly overkill. Don't start thinking about using Test::Class until issues like duplicate code in your test scripts start to annoy.

=item *

If you are distributing your code it is yet another module that the user has to have to run your tests (unless you distribute it with your test suite of course).

=item *

It probably chokes on early perls. I'm a happy v5.6.1 user and have done no testing on earlier perl versions. I'm more than willing to backport if anybody wants to donate some time on a box with other perl versions.

=item *

If you are used to the TestCase/Suite/Runner class structure used by JUnit and similar testing frameworks you may find Test::Unit more familiar (but try reading L</"HELP FOR CONFUSED JUNIT USERS"> before you give up).

=back


=head1 TEST CLASSES

A test class is just a class that inherits from Test::Class. Defining a test class is as simple as doing:

  package Example::Test;
  use base qw(Test::Class);

Since Test::Class does not provide its own test functions, but uses those provided by L<Test::More> and friends, you will nearly always also want to have:

  use Test::More;

to import the test functions into your test class.

=head1 TEST METHODS

You define test methods using the L<Test|/"Test"> attribute. For example:

  package Example::Test;
  use base qw(Test::Class);
  use Test::More;

  sub always_pass : Test { ok(1 == 1) };

This declares the C<always_pass> method as a test method that runs one test. 

If your test method runs more than one test, you should put the number of tests in brackets like this:

  sub addition : Test(2) {
      is(10 + 20, 30, 'addition works');
      is(20 + 10, 30, '  both ways');
  };

If you don't know the number of tests at compile time you use C<no_plan> like this.

  sub check_class : Test(no_plan) {
      my $objects = shift->{objects};
      isa_ok($_, "Object") foreach @$objects;
  };

(you can use L<num_method_tests()|/"num_method_tests"> and L<num_tests()|/"num_tests"> to set the number of tests at run time.)

You can run all the test methods in a class by doing:

  Example::Test->runtests

Test methods are run in ASCII order - so the execution order of the test methods defined above would be C<addition>, C<always_pass> and finally C<check_class>.

Most of the time you should not care what order tests are run in, but it can be useful. For example:

  sub _check_new {
      my $self = shift;
      isa_ok(Object->new, "Object") or $self->BAILOUT('new fails!');
  };

The leading C<_> will force the above method to run first - allowing the entire suite to be aborted before any other test methods run.


=head1 SETUP AND TEARDOWN METHODS

Test::Class allows you to define setup and teardown methods that are run before and after every test. For example:

  sub before : Test(setup)    { diag("running before test") };
  sub after  : Test(teardown) { diag("running after test") };

You can use setup and teardown methods to create objects that all your test methods use (a test I<fixture>). 

All setup, test and teardown methods are passed a test object which you can use to store your fixture objects. For example:

  sub _make_pig : Test(setup);
      my $self = shift;
      $self->{test_pig} = Pig->new;
  };

  sub born_hungry : Test {
      my $pig = shift->{test_pig};
      is($pig->hungry, 'pigs are born hungry');
  };

  sub eats : Test(3) {
      my $pig = shift->{test_pig};
      ok(  $pig->feed,   'pig fed okay');
      ok(! $pig->hungry, 'fed pig not hungry');
      ok(! $pig->feed,   'cannot feed full pig');
  };

You can also declare setup and teardown methods as running tests. For example you could check that the test pig survives each test method by doing:

  sub alive : Test(teardown => 1) {
      my $pig = shift->{test_pig};
      ok($pig->alive, 'pig survived tests' );
  };

You can even have a method run as both a setup and a teardown. For example:

  sub pig_status : Test(setup => teardown) {
      my $pig = shift->{test_pig};
      diag("The pig is " . ($pig->hungry ? "hungry" : "full"));
  };

Just like test methods, setup and teardown methods are run in alphabetical order before/after each test method. So L<runtests()|/"runtests"> would execute the above methods in the following order.

  1)  Setup methods for first test
        _make_pig()  before()  pig_status()

  2)  First test
        born_hungry()

  3)  Teardown methods for first test
        after()  alive()  pig_status()

  4)  Setup methods for second test
        _make_pig()  before()  pig_status()

  5)  Second test
        eats()

  6)  Teardown methods for second test
        after()  alive()  pig_status()


=head1 HANDLING EXCEPTIONS

If a setup, test or teardown method dies then L<runtests()|/"runtests"> will catch the exception and fail any remaining tests in the method. For example:

  sub test_object : Test(2) {
      my $object = Object->new;
      isa_ok($object, "Object") or die("could not create object\n");
      is($object->open, "open worked");
  };

will produce the following if the first test failed:

  not ok 1 - The object isa Object
  #     Failed test (t/runtests_die.t at line 15)
  #     The object isn't defined
  not ok 2 - test_object failed (could not create object)
  #     Failed test (t/runtests_die.t at line 27)

This can considerably simplify testing code that throws exceptions. 

Rather than having to explicitly check that the code exited normally (e.g. with L<Test::Exception/"lives_ok">) the test will fail automatically - without aborting the other test methods. For example contrast:

  use Test::Exception;

  my $file;
  lives_ok { $file = read_file('test.txt') } 'file read';
  is($file, "content", 'test file read');

with:

  sub read_file : Test {
      is(read_file('test.txt'), "content", 'test file read');
  };


=head1 SKIPPED TESTS

You can skip the rest of the tests in a method by returning from the method before all the test have finished running. The value returned is used as the reason for the tests being skipped.

This makes managing tests that can be skipped for multiple reasons very simple. For example:

  sub flying_pigs : Test(5) {
      my $pig = Pig->new;
      isa_ok($pig, 'Pig')           or return("cannot breed pigs")
      can_ok($pig, 'takeoff')       or return("pigs don't fly here");
      ok($pig->takeoff, 'takeoff')  or return("takeoff failed");
      ok( $pig->altitude > 0, 'Pig is airborne' );
      ok( $pig->airspeed > 0, '  and moving'    );
  };

If you run this test in an environment where C<Pig-E<gt>new> worked and the takeoff method existed, but failed when ran, you would get:

  ok 1 - The object isa Pig
  ok 2 - can takeoff
  not ok 3 - takeoff
  ok 4 # skip takeoff failed
  ok 5 # skip takeoff failed

You can also skip tests just as you do in Test::More or Test::Builder - see L<Test::More/"Conditional tests"> for more information. 

I<Note:> if you want to skip tests in a method with C<no_plan> tests then you have to explicitly skip the tests in the method - since Test::Class cannot determine how many tests should be skipped. For example:

  sub test_objects : Test(no_plan) {
      my $self = shift;
      my $objects = $self->{objects};
      if (@$objects) {
          isa_ok($_, "Object") foreach (@$objects);
      } else {
          $self->builder->skip("no objects to test");
      };
  };

Another way of overcoming this problem is to explicitly set the number of tests for the method at runtime using L<num_method_tests()|/"num_method_tests"> or L<"num_tests">.


=head1 TO DO TESTS

You can create todo tests just as you do in L<Test::More> and L<Test::Builder> by localising the C<$TODO> variable. For example:

  sub live_test : Test  {
      local $TODO = "live currently unimplemented";
      ok(Object->live, "object live");
  };

See L<Test::Harness/"Todo tests"> for more information.

=head1 EXTENDING TEST CLASSES BY INHERITANCE

One of the advantages of having a test class is that you can extend them by inheritance. For example consider the following test class for a C<Pig> object.

  package Pig::Test;
  use base qw(Test::Class);
  use Test::More;

  sub testing_class { "Pig" };
  sub new_args { (-age => 3) };

  sub setup : Test(setup) {
      my $self = shift;
      my $class = $self->testing_class;
      my @args = $self->new_args;
      $self->{pig} = $class->new( @args );
  };

  sub _creation : Test {
      my $self = shift;
      isa_ok($self->{pig}, $self->testing_class) 
              or $self->FAIL_ALL('Pig->new failed');
  };

  sub check_fields : Test {
      my $pig = shift->{pig};
      is($pig->age, 3, "age accessed");
  };

  ... other tests ...

Next consider C<NamedPig> a subclass of C<Pig> where you can give your pig a name.

We want to make sure that all the tests for the C<Pig> object still work for C<NamedPig>. We can do this by subclassing C<Pig::Test> and overriding the C<testing_class> and C<new_args> methods.

  package NamedPig::Test;
  use base qw(Pig::Test);
  use Test::More;

  sub testing_class { "NamedPig" };
  sub new_args { (shift->SUPER::new_args, -name => 'Porky') };

Now we need to test the name method. Let's do this by extending the C<check_fields> method.

  sub check_fields : Test(2) {
      my $self = shift;
      $self->SUPER::check_fields;   
      is($self->{pig}->name, 'Porky', 'name accessed');
  };

While the above works, the total number of tests for the method is dependant on the number of tests in its C<SUPER::check_fields>. If we add a test to C<Pig::Test-E<gt>check_fields> we will also have to update the number of tests of C<NamedPig::test-E<gt>check_fields>.

Test::Class allows us to state explicitly that we are adding tests to an existing method by using the C<+> prefix. Since we are adding a single test to C<check_fields> it can be rewritten as:

  sub check_fields : Test(+1) {
      my $self = shift;
      $self->SUPER::check_fields;
      is($self->{pig}->name, 'Porky', 'name accessed');
  };

With the above definition you can add tests to C<check_fields> in C<Pig::Test> without affecting C<NamedPig::Test>.


=head1 RUNNING TESTS

You have already seen that you can run all the test methods in a test class by doing:

  Example::Test->runtests

This is actually a shortcut for saying:

  Example::Test->new->runtests

The object created by C<Example::Test-E<gt>new> is the one passed to every setup, test and teardown method.

If you want to run multiple test objects in a single script you can pass L<runtests()|/"runtests"> a list of test objects. For example:

  my $o1 = Example::Test->new;
  my $o2 = Another::Test->new;
  # runs all the tests in $o1 and $o2
  $o1->runtests($o2);

Since, by definition, the base Test::Class has no tests you could also have written:

  my $o1 = Example::Test->new;
  my $o2 = Another::Test->new;
  Test::Class->runtests($o1, $o2);

Since you can pass L<runtests()|/"runtests"> class names instead of objects the above can be written more compactly as:

  Test::Class->runtests(qw( Example::Test Another::Test ))

In all of the above examples L<runtests()|/"runtests"> will look at the number of tests both test classes run and output an appropriate test header for L<Test::Harness> automatically.

What happens if you run test classes and normal tests in the same script? For example:

  Example::Test->runtests;
  ok(Example->new->foo, 'a test not in the test class');
  ok(Example->new->bar, 'ditto');

L<Test::Harness> will complain that it saw more tests than it expected since the test header output by L<runtests()|/"runtests"> will not include the two normal tests.

To overcome this problem you can pass an integer value to L<runtests()|/"runtests">. This is added to the total number of tests in the test header. So the problematic example can be rewritten as follows:

  Example::Test->runtests(+2);
  ok(Example->new->foo, 'a test not in the test class');
  ok(Example->new->bar, 'ditto');

If you prefer to write your test plan explicitly you can use L<expected_tests()|/"expected_tests"> to find out the number of tests a class/object is expected to run.

Since L<runtests()|/"runtests"> will not output a test plan if one has already been set the previous example can be written as:

  plan tests => 2 + Example::Test->expected_tests;
  Example::Test->runtests;
  ok(Example->new->foo, 'a test not in the test class');
  ok(Example->new->bar, 'ditto');

I<Remember:> Test objects are just normal perl objects. Test classes are just normal perl classes. Setup, test and teardown methods are just normal methods. You are completely free to have other methods in your class that are called from your test methods, or have object specific C<new> and C<DESTROY> methods. 

In particular you can override the new() method to pass parameters to your test object, or re-define the number of tests a method will run. See L<num_method_tests()|/"num_method_tests"> for an example. 


=head1 ORGANISING YOUR TEST CLASSES

You can, of course, organise your test modules as you wish. My personal preferences is:

=over 4

=item *

Name test classes with a suffix of C<::Test> so the test class for the C<Foo::Bar> module would be C<Foo::Bar::Test>.

=item *

Place all test classes in F<t/lib>.

You can use the INIT method to autorun tests.

=back


=head1 METHODS

=head2 Creating and running tests

=over 4

=cut


my $Tests = {};

sub _test_info {
	my $self = shift;
	return(ref($self) ? $self->{_test} : $Tests);
};

sub _method_info {
	my ($self, $class, $method) = @_;
	return($self->_test_info->{$class}->{$method});
};

sub _methods_of_class {
	my ($self, $class) = @_;
	return(values %{$self->_test_info->{$class}});
};


=item B<add_method>

Adds the specified method as a setup/test/teardown method.

=cut

sub add_method {
	my ($class, $name, $num_tests, $types) = @_;
	$Tests->{$class}->{$name} = 
			Test::Class::MethodInfo->new(
				name => $name, 
				num_tests => $num_tests,
				type => $types,
			);	
};


sub _new_method_info {
	my ($class, $method_name, $args) = @_;
	$args ||= "test => 1";
	my $num_tests = 0;
	my @types;
	foreach my $arg (split /\s*=>\s*/, $args) {
		if (Test::Class::MethodInfo->is_num_tests($arg)) {
			$num_tests = $arg;
		} elsif (Test::Class::MethodInfo->is_method_type($arg)) {
			push @types, $arg;
		} else {
			return(undef);
		};
	};
	push @types, TEST unless @types;
	$class->add_method($method_name, $num_tests, [@types]);
	return(1);
};


=item B<Test>

  # test methods
  sub method_name : Test { ... };
  sub method_name : Test(N) { ... };

  # setup methods
  sub method_name : Test(setup) { ... };
  sub method_name : Test(setup => N) { ... };

  # teardown methods
  sub method_name : Test(teardown) { ... };
  sub method_name : Test(teardown => N) { ... };

  # setup & teardown methods
  sub method_name : Test(setup => teardown) { ... };
  sub method_name : Test(setup => teardown => N) { ... };

Marks a method as a setup, test or teardown method. See L<runtests()|/"runtests"> for information on how to run methods declared with the C<Test> attribute.

N specifies the number of tests the method runs. 

=over 4

=item *

If N is an integer then the method should run exactly N tests.

=item *

If N is an integer with a C<+> prefix then the method is expected to call its C<SUPER::> method and extend it by running N additional tests.

=item *

If N is the string C<no_plan> then the method can run an arbritary number of tests.

=back

If N is not specified it defaults to C<1> for test methods, and C<0> for setup and teardown methods. 

You can change the number of tests that a method runs using L<num_method_tests()|/"num_method_tests"> or L<num_tests()|/"num_tests">.

=cut

sub Test : ATTR(CODE,RAWDATA) {
	my ($class, $symbol, $code_ref, $attr, $args) = @_;
	if ($symbol eq "ANON") {
		warn "cannot test anonymous subs\n";
		return;
	};
	my $name = *{$symbol}{NAME};
	$class->_new_method_info($name, $args)
			|| warn "bad test definition '$args' in $class->$name\n";	
};


=item B<new>

  $Tests = CLASS->new(KEY => VAL ...)
  $Tests2 = $Tests->new(KEY => VAL ...)

Creates a new test object (hash) containing the specified key/value pairs. 

The keys C<_test> and C<-test> are reserved for internal use and should not be used.

If called as an object method the existing object's key/value pairs are copied into the new object. Any key/value pairs passed to C<new> override those in the original object if duplicates occur.

Since the test object is passed to every test method as it runs it is a 
convenient place to store test fixtures. For example:

  sub make_fixture : Test(setup) {
      my $self = shift;
      $self->{object} = Object->new();
      $self->{dbh} = Mock::DBI->new(-type => normal);
  };

  sub test_open : Test {
      my $self = shift;
      my ($o, $dbh) = ($self->{object}, $self->{dbh});
      ok($o->open($dbh), "opened ok");
  };

See L<num_method_tests()|/"num_method_tests"> for an example of overriding C<new>.

=cut


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	$proto = {} unless ref($proto);
	my $self = bless {%$proto, @_}, $class;
	$self->{_test} = dclone($Tests);
	$self->{-test} = "the documentation says you shouldn't use this...";
	return($self);
};


sub _get_methods {
	my ($self, @types) = @_;
	my $test_class = ref($self) || $self;
	my %methods = ();
	foreach my $class (Class::ISA::self_and_super_path($test_class)) {
		foreach my $info ($self->_methods_of_class($class)) {
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
			$self->_get_methods(STARTUP, SHUTDOWN);
	my $num_startup_shutdown_methods = 
			$self->_total_num_tests(@startup_shutdown_methods);
	return(NO_PLAN) if $num_startup_shutdown_methods eq NO_PLAN;
	my @fixture_methods = $self->_get_methods(SETUP, TEARDOWN);
	my $num_fixture_tests = $self->_total_num_tests(@fixture_methods);
	return(NO_PLAN) if $num_fixture_tests eq NO_PLAN;
	my @test_methods = $self->_get_methods(TEST);
	my $num_tests = $self->_total_num_tests(@test_methods);
	return(NO_PLAN) if $num_tests eq NO_PLAN;
	return($num_startup_shutdown_methods + $num_tests + @test_methods * $num_fixture_tests);
};


=item B<expected_tests>

  $n = $Tests->expected_tests
  $n = CLASS->expected_tests
  $n = $Tests->expected_tests(TEST, ...)
  $n = CLASS->expected_tests(TEST, ...)

Returns the total number of tests that L<runtests()|/"runtests"> will run on the specified class/object. This includes tests run by any setup and teardown methods.

Will return C<no_plan> if the exact number of tests is undetermined (i.e. if any setup, test or teardown method has an undetermined number of tests).

The C<expected_tests> of an object after L<runtests()|/"runtests"> has been executed will include any runtime changes to the expected number of tests made by L<num_tests()|/"num_tests"> or L<num_method_tests()|/"num_method_tests">.

C<expected_tests> can also take an optional list of test objects, test classes and integers. In this case the result is the total number of expected tests for all the test/object classes (including the one the method was applied to) plus any integer values.

C<expected_tests> is useful when you're integrating one or more test classes into a more traditional test script, for example:

  use Test::More;
  use My::Test::Class;

  plan tests => My::Test::Class->expected_tests_of(+2);

  ok(whatever, 'a test');
  ok(whatever, 'another test');
  My::Test::Class->runtests;

=cut


sub expected_tests {
	my $total = 0;
	foreach my $test (@_) {
		if (UNIVERSAL::isa($test, __PACKAGE__)) {
			my $n = $test->_num_expected_tests;
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
			my $info = $self->_method_info($class, $method);
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
	$self->_show_header(@$tests) unless $Builder->has_plan;
	$Builder->ok(0, "$message died ($exception)");
};


sub _run_method {
	my ($self, $method, $tests) = @_;
	my $num_start = $Builder->current_test;
	my $skip_reason = eval {$self->$method};
	my $exception = $@;
	chomp($exception) if $exception;
	my $num_done = $Builder->current_test - $num_start;
	my $num_expected = $self->_total_num_tests($method);
	$num_expected = $num_done if $num_expected eq NO_PLAN;
	if ($num_done == $num_expected) {
		$self->_exception_failure($method, $exception, $tests) 
				unless $exception eq '';
	} elsif ($num_done > $num_expected) {
		$Builder->diag("expected $num_expected test(s) in $method, $num_done completed\n");
	} else {
		until (($Builder->current_test - $num_start) >= $num_expected) {
			if ($exception ne '') {
				$self->_exception_failure($method, $exception, $tests);
				$skip_reason = "$method died";
				$exception = '';
			} else {
				$Builder->skip($skip_reason || $method);
			};
		};
	};
	return($self->_all_ok_from($num_start));
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


=item B<runtests>

  $allok = $Tests->runtests
  $allok = CLASS->runtests
  $allok = $Tests->runtests(TEST, ...)
  $allok = CLASS->runtests(TEST, ...)

Run, in alphabetical order, all the test methods of the given test object. Calling C<runtests> as a class method is the same as doing C<CLASS-E<gt>new-E<gt>runtests>. Returns C<1> if all the tests pass, C<0> otherwise.

=over 4

=item *

All setup methods are run (in alphabetical order) before each test method.

=item *

All teardown methods are run (in alphabetical order) after each test method has finished.

=item *

If a method is declared as both a setup and a teardown method, it is run before and after every test method.

=back

Unless you have already specified a test plan using Test::Builder (or Test::More, et al) C<runtests> will set the test plan just before the first method that runs a test is executed. 

If a method throws an exception before the expected number of tests for that method have run, all remaining tests for that method are failed. The stringified exception is used as the reason for failure. For example:

  sub test_object : Test(2) {
      my $object = Object->new;
      isa_ok($object, "Object") or die("could not create object\n");
      is($object->open, "open worked");
  };

Would produce something like this if the first test failed:

  not ok 1 - The object isa Object
  #     Failed test (t/runtests_die.t at line 15)
  #     The object isn't defined
  not ok 2 - test_object failed (could not create object)
  #     Failed test (t/runtests_die.t at line 27)

If a method returns before the expected number of tests for that method have run, all remaining tests for that method are skipped. The return value is used as the reason for skipping the tests, or the method name of the test if the return value is false. For example:

  sub darwin_only : Test {
      return("darwin only test") unless $^O eq "darwin";
      ok(-w "/Library", "/Library writable") 
  };

Will produce:

  ok 1 # skip darwin only test

unless the test is run on the darwin OS.

Just like L<expected_tests()|/"expected_tests">, C<runtests> can take an optional list of test object/classes and integers. All of the test object/classes are run. Any integers are added to the total number of tests shown in the test header output by C<runtests>. 

For example, you can run all the tests in test classes A, B and C, plus one additional normal test by doing:

    Test::Class->runtests(qw(A B C), +1);
    ok(1==1, 'non class test');

If the environment variable C<TEST_VERBOSE> is set C<runtests> will display the name of each test method before it runs.

=cut


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
		my @setup = $t->_get_methods(SETUP);
		my @teardown = $t->_get_methods(TEARDOWN);
		foreach my $method ($t->_get_methods(STARTUP)) {
			$t->_show_header(@tests) 
					unless $Builder->has_plan 
					|| $t->_total_num_tests($method) eq '0';
			my $method_passed = $t->_run_method($method, \@tests);
			$all_passed &&= $method_passed;
		};
		foreach my $test ($t->_get_methods(TEST)) { 
			local $Current_method = $test;
		   	$Builder->diag("\n$class->$test") if $ENV{TEST_VERBOSE};
			foreach my $method (@setup, $test, @teardown) {
				$t->_show_header(@tests) 
						unless $Builder->has_plan 
						|| $t->_total_num_tests($method) eq '0';
				my $method_passed = $t->_run_method($method, \@tests);
				$all_passed &&= $method_passed;
			};
		};
		foreach my $method ($t->_get_methods(SHUTDOWN)) {
			$t->_show_header(@tests) 
					unless $Builder->has_plan 
					|| $t->_total_num_tests($method) eq '0';
			my $method_passed = $t->_run_method($method, \@tests);
			$all_passed &&= $method_passed;
		};

	};
	return($all_passed);
};


sub _find_calling_test_class {
	my $level = 0;
	while (my $class = caller(++$level)) {
		next if $class eq __PACKAGE__;
		return($class) if $class->isa(__PACKAGE__);
	}; 
	return(undef);
};


=item B<autorun>

=cut

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

=item B<run_all_classes>

=cut

sub run_all_classes {
	my $class = shift;
	grep {UNIVERSAL::isa($_, $class) && $_->autorun} 
			Devel::Symdump->rnew->packages;
};


=back

=cut

=head2 Fetching and setting a method's test number

=over 4

=item B<num_method_tests>

  $n = $Tests->num_method_tests($method_name)
  $Tests->num_method_tests($method_name, $n)
  $n = CLASS->num_method_tests($method_name)
  CLASS->num_method_tests($method_name, $n)

Fetch or set the number of tests that the named method is expected to run.

If the method has an undetermined number of tests then $n should be the string C<no_plan>.

If the method is extending the number of tests run by the method in a superclass then $n should have a C<+> prefix.

When called as a class method any change to the expected number of tests applies to all future test objects. Existing test objects are unaffected. 

When called as an object method any change to the expected number of tests applies to that object alone.

C<num_method_tests> is useful when you need to set the expected number of tests at object creation time, rather than at compile time.

For example, the following test class will run a different number of tests depending on the number of objects supplied.

  package Object::Test; 
  use base qw(Test::Class);
  use Test::More;

  sub new {
      my $class = shift;
      my $self = $class->SUPER::new(@_);
      my $num_objects = @{$self->{objects}};
      $self->num_method_tests('test_objects', $num_objects);
      return($self);
  };

  sub test_objects : Test(no_plan) {
    my $self = shift;
    ok($_->open, "opened $_") foreach @{$self->{objects}};
  };
  ...
  # This runs two tests
  Object::Test->new(objects => [$o1, $o2]);

The advantage of setting the number of tests at object creation time, rather than using a test method without a plan, is that the number of expected tests can be determined before testing begins. This allows better diagnostics from L<runtests()|/"runtests">, L<Test::Builder> and L<Test::Harness>.

C<num_method_tests> is a protected method and can only be called by subclasses of Test::Class. It fetches or sets the expected number of tests for the methods of the class it was I<called in>, not the methods of the object/class it was I<applied to>. This allows test classes that use C<num_method_tests> to be subclassed easily.

For example, consider the creation of a subclass of Object::Test that ensures that all the opened objects are read-only:

  package Special::Object::Test;
  use base qw(Object::Test);
  use Test::More;

  sub test_objects : Test(+1) {
      my $self = shift;
      $self->SUPER::test_objects;
      my @bad_objects = grep {! $_->read_only} (@{$self->{objects}});
      ok(@bad_objects == 0, "all objects read only");
  };
  ...
  # This runs three tests
  Special::Object::Test->new(objects => [$o1, $o2]);

Since the call to C<num_method_tests> in Object::Test only affects the C<test_objects> of Object::Test, the above works as you would expect.

=cut


sub num_method_tests {
	my ($self, $method, $n) = @_;
	my $class = $self->_find_calling_test_class;
	croak "not called in a Test::Class" unless $class;
	my $info = $self->_method_info($class, $method);
	croak "$method is not a test method of class $class" unless $info;
	$info->num_tests($n) if defined($n);
	return($info->num_tests);
};


=item B<num_tests>

  $n = $Tests->num_tests
  $Tests->num_tests($n)
  $n = CLASS->num_tests
  CLASS->num_tests($n)

Set or return the number of expected tests associated with the currently running test method. This is the same as calling L<num_method_tests()|/"num_method_tests"> with a method name of L<current_method()|/"current_method">.

For example:

  sub txt_files_readable : Test(no_plan) {
      my $self = shift;
      my @files = <*.txt>;
      $self->num_tests(scalar(@files));
      ok(-r $_, "$_ readable") foreach (@files);
  };

Setting the number of expected tests at runtime, rather than just having a C<no_plan> test method, allows L<runtests()|/"runtests"> to display appropriate diagnostic messages if the method runs a different number of tests.

=back

=cut


sub num_tests {
	my ($self, $n) = @_;
	croak "num_tests need to be called within a test method"
			unless defined $Current_method;
	return($self->num_method_tests($Current_method, $n));
};



=head2 Support methods

=over 4

=item B<builder>

  $Tests->builder

Returns the underlying L<Test::Builder> object that Test::Class uses. For example:

  sub test_close : Test {
      my $self = shift;
      my ($o, $dbh) = ($self->{object}, $self->{dbh});
      $self->builder->ok($o->close($dbh), "closed ok");
  };

=cut


sub builder { $Builder };


=item B<current_method>

  $method_name = $Tests->current_method
  $method_name = CLASS->current_method

Returns the name of the test method currently being executed by L<runtests()|/"runtests">, or C<undef> if L<runtests()|/"runtests"> has not been called. 

The method name is also available in the setup and teardown methods that run before and after the test method. This can be useful in producing diagnostic messages, for example:

  sub test_invarient : Test(teardown => 1) {
      my $self = shift;
      my $m = $self->current_method;
      ok($self->invarient_ok, "class okay after $m");
  };

=cut


sub current_method { $Current_method };


=item B<BAILOUT>

  $Tests->BAILOUT($reason)
  CLASS->BAILOUT($reason)

Things are going so badly all testing should terminate, including running any additional test scripts invoked by L<Test::Harness>. This is exactly the same as doing:

  $self->builder->BAILOUT

See L<Test::Builder/"BAILOUT"> for details. Any teardown methods are I<not> run.

=cut


sub BAILOUT {
	my ($self, $reason) = @_;
	$Builder->BAILOUT($reason);
};


=item B<FAIL_ALL>

  $Tests->FAIL_ALL($reason)
  CLASS->FAIL_ALL($reason)

Things are going so badly all the remaining tests in the current script should fail. Exits immediately with the number of tests failed, or C<254> if more than 254 tests were run. Any teardown methods are I<not> run.

This does not affect the running of any other test scripts invoked by L<Test::Harness>.

For example, if all your tests rely on the ability to create objects then you might want something like this as an early test:

  sub _test_new : Test(3) {
      my $self = shift;
      isa_ok(Object->new, "Object") 
          || $self->FAIL_ALL('cannot create Objects');
      ...
  };

=cut


sub FAIL_ALL {
	my ($self, $reason) = @_;
	my $expected = $Builder->expected_tests || $Builder->current_test+1;
	$Builder->expected_tests($expected) unless $Builder->has_plan();
	$Builder->ok(0, $reason) until $Builder->current_test >= $expected;
	my $num_failed = grep(! $_, $Builder->summary);
	exit($num_failed < 254 ? $num_failed : 254);
};


=item B<SKIP_ALL>

  $Tests->SKIP_ALL($reason)
  CLASS->SKIP_ALL($reason)

Things are going so badly all the remaining tests in the current script should be skipped. Exits immediately with C<0> - teardown methods are I<not> run.

This does not affect the running of any other test scripts invoked by L<Test::Harness>.

For example, if you had a test script that only applied to the darwin OS you could write:

  sub _darwin_only : Test(setup) {
      my $self = shift;
      $self->SKIP_ALL("darwin only") unless $^O eq "darwin";    
  };

=cut


sub SKIP_ALL {	
	my ($self, $reason) = @_;
	$Builder->skip_all($reason) unless $Builder->has_plan;
	my $expected = $Builder->expected_tests || $Builder->current_test+1;
	$Builder->skip($reason) until ($Builder->current_test >= $expected);
	exit(0);
}


=back



=head1 HELP FOR CONFUSED JUNIT USERS

This section is for people who have used JUnit (or similar) and are confused because they don't see the TestCase/Suite/Runner class framework they were expecting.

=over 4

=item B<Class Assert>

The test assertions provided by Assert correspond to the test functions provided by the L<Test::Builder> based modules (L<Test::More>, L<Test::Exception>, L<Test::Differences>, etc.)

Unlike JUnit the test functions supplied by Test::More et al do I<not> throw exceptions on failure. They just report the failure to STDOUT where it is collected by L<Test::Harness>. This means that where you have

  sub foo : Test(2) {
      ok($foo->method1);
      ok($foo->method2);
  };

The second test I<will> run if the first one fails. You can emulate the JUnit way of doing it by throwing an explicit exception on test failure:

  sub foo : Test(2) {
      ok($foo->method1) or die "method1 failed";
      ok($foo->method2);
  };

The exception will be caught by Test::Class and the other test automatically failed.

=item B<Class TestCase>

Test::Class corresponds to TestCase in JUnit.

In Test::Class setup, test and teardown methods are marked explicitly using the L<Test|/"Test"> attribute. Since we need to know the total number of tests to provide a test plan for L<Test::Harness> we also state how many tests each method runs.

Unlike JUnit you can have multiple setup/teardown methods in a class.

=item B<Class TestSuite>

Test::Class also does the work that would be done by TestSuite in JUnit.

Since the methods are marked with attributes Test::Class knows what is and isn't a test method. This allows it to run all the test methods without having the developer create a suite manually, or use reflection to dynamically determine the test methods by name. See the L<runtests()|/"runtests"> method for more details.

You can easily create a compound suite by using L<runtests()|/"runtests">. So, where in JUnit you would do:

In Test::Class you would do:

	Test::Class->runtest(qw( Foo Bar Ni ));

or, if you want to create a class that you can inherit 

	package Foo;
	use base qw(Test::Class);

	sub new {
	};

	sub suite : Test(no_plan) {
	};

The running order of the test methods is fixed in Test::Class. Methods are executed in alphabetical order.

Unlike JUnit, Test::Class currently does not allow you to run individual test methods.

=item B<Class TestRunner>

L<Test::Harness> does the work of the TestRunner in JUnit. It collects the test results (sent to STDOUT) and collates the results.

Unlike JUnit there is no distinction made by Test::Harness between errors and failures. However, it does support skipped and todo test - which JUnit does not.

If you want to write your own test runners you should look at L<Test::Harness::Straps>.

=back


=head1 OTHER MODULES FOR XUNIT TESTING IN PERL

In addition to Test::Class there are two other distributions for xUnit testing in perl. Both have a longer history than Test::Class and might be more suitable for your needs. 

I am biased since I wrote Test::Class - so please read the following with appropriate levels of scepticism. If you think I have misrepresented the modules please let me know.

=over 4

=item B<Test::SimpleUnit>

A very simple unit testing framework. If you are looking for a lightweight single module solution this might be for you.

The advantage of L<Test::SimpleUnit> is that it is simple! Just one module with a smallish API to learn. 

Of course this is also the disadvantage. 

It's not class based so you cannot create testing classes to reuse and extend.

It doesn't use L<Test::Builder> so it's difficult to extend or integrate with other testing modules. If you are already familiar with L<Test::Builder>, L<Test::More> and friends you will have to learn a new test assertion API. It does not support L<todo tests|Test::Harness/"Todo tests">.

=item B<Test::Unit>

L<Test::Unit> is a port of JUnit L<http://www.junit.org/> into perl. If you have used JUnit then the Test::Unit framework should be very familiar.

It is class based so you can easily reuse your test classes and extend by subclassing. You get a nice flexible framework you can tweak to your heart's content. If you can run Tk you also get a graphical test runner.

However, Test::Unit is not based on L<Test::Builder>. You cannot easily move Test::Builder based test functions into Test::Unit based classes. You have to learn another test assertion API. 

Test::Unit implements it's own testing framework separate from L<Test::Harness>. You can retrofit *.t scripts as unit tests, and output test results in the format that L<Test::Harness> expects, but things like L<todo tests|Test::Harness/"Todo tests"> and L<skipping tests|Test::Harness/"Skipping tests"> are not supported. 

=back

... summary of Test::Class advantages over other modules ...

Test::Class allows you to easily isolate all the test for a module in a single file, making testing a single module easier.


=head1 BUGS

None known at the time of writing.

If you find any bugs please let me know by e-mail, or report the problem with L<http://rt.cpan.org/>.


=head1 TO DO


I'm thinking about the following issues - if you want it done poke away (or write a patch :-)

=over 4

=item *

The teardown method should be able to introspect on whether the test method succeeded or failed, number of expected tests, number of tests run, etc.

=item *

Look at the issue David reported in <C85FE3B4-5D5A-11D7-B1D2-0003931A964A@kineticode.com>

=item *

Look at the issue with spaces and attributes that David reported in <4A5B4B14-2FD5-11D7-A166-0003931A964A@wheeler.net>

=item *

Add a "stage" method to find out whether you're in setup, teardown or test method stage.

=item *

Add patch to deal with extra spaces in attribute args

=item *

Add David Wheeler's idea to make automatically load classes

=item *

An advantage of Test::Class is that test can be documented as modules

=item *

Add section on using self-shunt pattern with Test::Class.

=item *

Make sure all private methods are called as functions to prevent them being overridden by subclasses

=item *

Add comparison to Test::Extreme

=item *

Think about whether we can report the line # of the method that failed, rather than the location of the call to runtests

=item *

Remove BAILOUT

=item *

Add other Test::Builder modules to See Also.

=item *

Should also allow no_plan in expected_tests, run_tests, et al.

=item *

Should use inside-out objects to remove -test/test restrictions

=item *

Give a warning if not compiling in CHECK phase. Sort out the bogus ANON messages from Attribute::Handlers. In fact, move completely away from A::H so it works correctly with MI and custom DESTROY handlers.

=item *

Make SKIP_ALL, FAIL_ALL just exit the object

=item *

Reserve a namespace for future T::C methods

=item *

Add Module::Build support.

=item *

Solve http://use.perl.org/~ethan/journal/14815

=item *

Should probably have some examples to show why setting the number of tests is better than using C<no_plan>.

=item *

Have the option of making test methods fail after the first failing test, for those who prefer that style.

=item *

Have the test name of C<Test::Builder::ok> default to L<current_method()|/"current_method">.

=item *

Think about making it work without attributes for older perls.

=item * 

Finish cleaning up up Test::Class documentation

=item *

Clean up Test::Class::Tutorial

=back

If you think this module should do something that it doesn't (or does something that it shouldn't) please let me know.


=head1 ACKNOWLEGEMENTS

This is yet another implementation of the ideas from Kent Beck's Testing Framework paper (INSERT URL HERE).

Thanks to Michael G Schwern, Tony Bowden, David Wheeler and all the fine folk on perl-qa for their feedback and suggestions.

This module wouldn't be possible without the excellent L<Test::Builder>. Thanks to chromatic <chromatic@wgz.org> and Michael G Schwern <schwern@pobox.com> for creating such a useful module.


=head1 AUTHOR

Adrian Howard <adrianh@quietstars.com>

If you can spare the time, please drop me a line if you find this module useful.


=head1 SEE ALSO

=over 4

=item L<Test::Class::Tutorial>

A gentle introduction to many of the features of Test::Class.

=back

L<Test::Builder> provides a consistent backend for building test libraries. The following modules are all built with L<Test::Builder>:

=over 4

=item L<Test::Simple> & L<Test::More>

Basic utilities for writing tests.

=item L<Test::Differences>

Test strings and data structures and show differences if not ok.

=item L<Test::Exception>

Convenience routines for testing exception based code.

=item L<Test::Inline>

Inlining your tests next to the code being tested.

=back

The following are not based on Test::Builder, but may be of interest.

=over 4

=item L<Test::Unit>

Perl unit testing framework closely modelled on JUnit. 

=item L<Test::SimpleUnit>

A very simple unit testing framework. 

=back

=head1 LICENCE

Copyright 2002 Adrian Howard, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


1;
