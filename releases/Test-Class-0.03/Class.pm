#! /usr/bin/perl -w

package Test::Class;
use 5.006;
use strict;
use warnings;
use Carp;
use Class::ISA;
use Test::Builder;
use Attribute::Handlers;
use Storable qw(dclone);
our $VERSION = '0.03';



=head1 NAME

Test::Class - Easily create test classes in an xUnit style.

=head1 SYNOPSIS

  package My::Class::Test;
  use base qw(Test::Class);

  sub new {
      my $class = shift;
      my $self = $class->SUPER::new(@_);
      my $n = $self->num_method_tests('test_method')
      $self->num_method_tests('test_method', 4)
      return($self);
  };

  sub test_method : Test(no_plan); {
      my $self = shift;
      my $method_name = $self->current_method;
      my $n = $self->num_tests;
      $self->num_tests(3);
      my $total = $self->total_num_tests;
  };

  sub method : Test { ... };
  sub method : Test(N) { ... };
  sub method : Test(setup) { ... };
  sub method : Test(setup => N) { ... };
  sub method : Test(teardown) { ... };
  sub method : Test(teardown => N) { ... };
  sub method : Test(setup => teardown) { ... };
  sub method : Test(setup => teardown => N) { ... };

  my $Tests = My::Class::Test->new;

  $Tests->BAILOUT($reason)
  $Tests->SKIP_ALL($reason)
  $Tests->FAIL_ALL($reason)

  my $builder = $self->builder

  my $total = $Tests->total_num_tests('test');

  my $expected = $Tests->expected_tests;

  my @setup = $Tests->setup_methods;
  my @tests = $Tests->test_methods;
  my @teardown = $Tests->teardown_methods

  my $all_ok = $Tests->runtests;

=head1 DESCRIPTION

Test::Class provides a simple way of creating classes and objects to test your code in an xUnit style.

Built using L<Test::Builder> it is designing to work with other Test::Builder based modules (L<Test::More>, L<Test::Differences>, L<Test::Exception>, etc.)

I<Note:> This module will make more sense if you are already familiar with the "standard" mechanisms for testing perl code. Those unfamiliar  with L<Test::Harness>, L<Test::Simple>, L<Test::More> and friends should go take a look at them now. 

I<Note:> This is an early release. Things may change. Be warned. 

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

A long time ago (well in 1994) Kent Beck wrote a testing framework for Smalltalk called SUnit. It was popular. You can read a copy of his original paper at L<http:E<sol>E<sol>www.xprogramming.comE<sol>testfram.htm>.

Later Kent Beck and Erich Gamma created JUnit for testing Java L<http:E<sol>E<sol>www.junit.orgE<sol>>. It was popular too.

Now there xUnit frameworks for every language from Ada to XSLT. You can find a list at L<http:E<sol>E<sol>www.xprogramming.comE<sol>software.htm>.

While xUnit frameworks are traditionally associated with unit testing they are also useful in the creation of functional/acceptance tests.

Test::Class is (yet another) implementation of xUnit style testing in perl. 

=head2 Other modules for xUnit testing in perl

In addition to Test::Class there are two other distributions for xUnit testing in perl. Both have a longer history than Test::Class and might be more suitable for your needs. 

I am biased since I wrote Test::Class - so please read the following with appropriate levels of scepticism. If you think I have misrepresented the modules please let me know.

=over 4

=item Test::SimpleUnit

A very simple unit testing framework. If you are looking for a lightweight single module solution this might be for you.

The advantage of L<Test::SimpleUnit> is that it is simple! Just one module with a smallish API to learn. 

Of course this is also the disadvantage. 

It's not class based so you cannot create testing classes to reuse and extend.

It doesn't use L<Test::Builder> so it's difficult to extend or integrate with other testing modules. If you are already familiar with L<Test::Builder>, L<Test::More> and friends you will have to learn a new test assertion API. It does not support L<todo tests|Test::Harness/"Todo tests">.

=item Test::Unit

L<Test::Unit> is a port of JUnit L<http:E<sol>E<sol>www.junit.orgE<sol>> into perl. If you have used JUnit then the Test::Unit framework should be very familiar.

It is class based so you can easily reuse your test classes and extend by subclassing. You get a nice flexible framework you can tweak to your heart's content. If you can run Tk you also get a graphical test runner.

However, Test::Unit is not based on L<Test::Builder>. You cannot easily move Test::Builder based test functions into Test::Unit based classes. You have to learn another test assertion API. 

Test::Unit implements it's own testing framework separate from L<Test::Harness>. You can retrofit *.t scripts as unit tests, and output test results in the format that L<Test::Harness> expects, but things like L<todo tests|Test::Harness/"Todo tests"> and L<skipping tests|Test::Harness/"Skipping tests"> are not supported. 

=back

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

If you are used to the TestCase/Suite/Runner class structure used by JUnit and similar testing frameworks you may find Test::Unit more familiar (but try reading L</"Test::Class for JUnit users"> before you give up).

=back

=head2 Test::Class for JUnit users

This section is for people who have used JUnit (or similar) and are confused because they don't see the TestCase/Suite/Runner class framework they were expecting.

=over 4

=item Class Assert

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

=item Class TestCase

Test::Class corresponds to TestCase in JUnit.

In Test::Class setup, test and teardown methods are marked explicitly using the L</"Test"> attribute. Since we need to know the total number of tests to provide a test plan for L<Test::Harness> we also state how many tests each method runs.

Unlike JUnit you can have multiple setup/teardown methods in a class.

=item Class TestSuite

Test::Class also does the work that would be done by TestSuite in JUnit.

Since the methods are marked with attributes Test::Class knows what is and isn't a test method. This allows it to run all the test methods without having the developer create a suite manually, or use reflection to dynamically determine the test methods by name. See the L</"runtests"> method for more details.

The running order of the test methods is fixed in Test::Class. Methods are executed in alphabetical order.

Unlike JUnit, Test::Class currently does not allow you to run individual test methods.

=item Class TestRunner

L<Test::Harness> does the work of the TestRunner in JUnit. It collects the test results (sent to STDOUT) and collates the results.

Unlike JUnit there is no distinction made by Test::Harness between errors and failures. However, it does support skipped and todo test - which JUnit does not.

If you want to write your own test runners you should look at L<Test::Harness::Straps>.

=back

=head1 TEST CLASSES

A test class is just a class that inherits from Test::Class. Defining a test class is as simple as doing:

  package Example::Test;
  use base qw(Test::Class);

Since Test::Class does not provide its own test functions, but uses those provided by L<Test::More> and friends, you will nearly always also want to have:

  use Test::More;

to import the test functions into your test class.

=head1 TEST METHODS

You define test methods using the L</"Test"> attribute. For example:

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

(you can use L</"num_method_tests"> and L</"num_tests"> to set the number of tests at run time.)

You can run all the test methods in a class by doing:

  Example::Test->runtests

Test methods are run in alphabetical order - so the execution order of the test methods defined above would be C<addition>, C<always_pass> and finally C<check_class>.

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

Just like test methods, setup and teardown methods are run in alphabetical order before/after each test method. So L</"runtests"> would execute the above methods in the following order.

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

=head1 USING EXCEPTIONS TO FAIL TESTS

If a test method dies then L</"runtests"> will catch the exception and fail any remaining tests in the method. For example:

  sub test_open : Test(2) {
      my $object = Object->new;
      isa_ok($object, "Object") or die("could not create object");
      is($object->open, "open worked");
  };

will produce the following if the first test failed:

  not ok 1 - The object isa Object
  #     Failed test (t/runtests_die.t at line 15)
  #     The object isn't defined
  not ok 2 - could not create object
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

I<Note:> if you want to fail tests after an exception in a method with C<no_plan> tests then you will have to explicitly catch the exception and fail the tests in the method - since Test::Class cannot determine how many tests should be failed. For example:

  sub test_objects : Test(no_plan) {
      lives_ok { $file = read_file('test.txt') } 'file read';
      is($file, "content", 'test file read');
  };

Another way of overcoming this problem is to explicitly set the number of tests for the method at runtime using L</"num_method_tests"> or L<"num_tests">.


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

Another way of overcoming this problem is to explicitly set the number of tests for the method at runtime using L</"num_method_tests"> or L<"num_tests">.


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

If you want to run multiple test objects in a single script you can pass L</"runtests"> a list of test objects. For example:

  my $o1 = Example::Test->new;
  my $o2 = Another::Test->new;
  # runs all the tests in $o1 and $o2
  $o1->runtests($o2);

Since, by definition, the base Test::Class has no tests you could also have written:

  my $o1 = Example::Test->new;
  my $o2 = Another::Test->new;
  Test::Class->runtests($o1, $o2);

Since you can pass L</"runtests"> class names instead of objects the above can be written more compactly as:

  Test::Class->runtests(qw( Example::Test Another::Test ))

In all of the above examples L</"runtests"> will look at the number of tests both test classes run and output an appropriate test header for L<Test::Harness> automatically.

What happens if you run test classes and normal tests in the same script? For example:

  Example::Test->runtests;
  ok(Example->new->foo, 'a test not in the test class');
  ok(Example->new->bar, 'ditto');

L<Test::Harness> will complain that it saw more tests than it expected since the test header output by L</"runtests"> will not include the two normal tests.

To overcome this problem you can pass an integer value to L</"runtests">. This is added to the total number of tests in the test header. So the problematic example can be rewritten as follows:

  Example::Test->runtests(+2);
  ok(Example->new->foo, 'a test not in the test class');
  ok(Example->new->bar, 'ditto');

If you prefer to write your test plan explicitly you can use L</"expected_tests"> to find out the number of tests a class/object is expected to run.

Since L</"runtests"> will not output a test plan if one has already been set the previous example can be written as:

  plan tests => 2 + Example::Test->expected_tests;
  Example::Test->runtests;
  ok(Example->new->foo, 'a test not in the test class');
  ok(Example->new->bar, 'ditto');

I<Remember:> Test objects are just normal perl objects. Test classes are just normal perl classes. Setup, test and teardown methods are just normal methods. You are completely free to have other methods in your class that are called from your test methods, or have object specific C<new> and C<DESTROY> methods. 

In particular you can override the new() method to pass parameters to your test object, or re-define the number of tests a method will run. See L</"num_method_tests"> for an example. 

=head1 ORGANISING YOUR TEST CLASSES

You can, of course, organise your test modules as you wish. My personal preferences is:

=over 4

=item *

Name test classes with a suffix of C<::Test> so the test class for the C<Foo::Bar> module would be C<Foo::Bar::Test>.

=item *

Place all test classes in F<t/lib>.

=back

=head1 METHODS

=over 4

=cut



=item new

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

See L</"num_method_tests"> for an example of overriding C<new>.

=cut

my $Tests = {};

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	$proto = {} unless ref($proto);
	my $self = bless {%$proto, @_}, $class;
	$self->{_test} = dclone($Tests);
	$self->{-test} = "the documentation says you shouldn't use this...";
	return($self);
};



=item current_method

  $method_name = $Tests->current_method
  $method_name = CLASS->current_method

Returns the name of the test method currently being executed by L</"runtests">, or C<undef> if L</"runtests"> has not been called. 

The method name is also available in the setup and teardown methods that run before and after the test method. This can be useful in producing diagnostic messages, for example:

  sub test_invarient : Test(teardown => 1) {
      my $self = shift;
      my $m = $self->current_method;
      ok($self->invarient_ok, "class okay after $m");
  };

=cut

our $Current_method = undef;
sub current_method { $Current_method };



=item builder

  $Tests->builder

Returns the underlying L<Test::Builder> object that Test::Class uses. For example:

  sub test_close : Test {
      my $self = shift;
      my ($o, $dbh) = ($self->{object}, $self->{dbh});
      $self->builder->ok($o->close($dbh), "closed ok");
  };

=cut

my $Builder = Test::Builder->new;
sub builder { $Builder };



# hmmm... this misses the case where you have no_plan and have
# not run a test...
sub _has_plan { $Builder->expected_tests || $Builder->current_test };


sub _is_num_tests { shift =~ m/^(no_plan)|(\+?\d+)$/s };

sub _is_method_type { shift =~ m/^(setup|tests|teardown)$/s };

sub _parse_args {
	my $args = shift;
	my $info = {num_tests => 0};
	$args = "tests => 1" unless defined($args);
	foreach my $arg (split /\s*=>\s*/, $args) {
		if (_is_num_tests($arg)) {
			$info->{num_tests} = $arg;
		} elsif (_is_method_type($arg)) {
			$info->{$arg} = 1;
		} else {
			return(undef);
		};
	};
	$info->{tests} = 1
			unless $info->{setup} || $info->{teardown};
	return($info);
};



=item Test Attribute

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

Marks a method as a setup, test or teardown method. See L</"runtests"> for information on how to run methods declared with the C<Test> attribute.

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

You can change the number of tests that a method runs using L</"num_method_tests"> or L</"num_tests">.

=cut

sub Test : ATTR(CODE,RAWDATA) {
	my ($class, $symbol, $code_ref, $attr, $args) = @_;
	if ($symbol eq "ANON") {
		warn "cannot test anonymous subs\n";
		return;
	};
	my $name = *{$symbol}{NAME};
	my $info = _parse_args($args);	
	if ($info) {
		$Tests->{$class}->{$name} = $info;
	} else {
		warn "bad test definition '$args' in $class->$name\n";
	};	
};



=item BAILOUT

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



=item SKIP_ALL

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
	if ($self->_has_plan) {
		my $expected = $Builder->expected_tests
				|| $Builder->current_test + 1;
		$Builder->skip($reason)
				until ($Builder->current_test >= $expected);
	} else {
		$Builder->skip_all($reason);
	};
	exit(0);
}



=item FAIL_ALL

  $Tests->FAIL_ALL($reason)
  CLASS->FAIL_ALL($reason)

Things are going so badly all the remaining tests in the current script should fail. Exits immediately with C<0>. Any teardown methods are I<not> run.

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
	$Builder->expected_tests($expected) unless $self->_has_plan();
	$Builder->ok(0, $reason) until $Builder->current_test >= $expected;
	exit(255);
};



sub _Tests {
	my $self = shift;
	return(ref($self) ? $self->{_test} : $Tests);
};


sub _get_methods {
	my ($self, $type) = @_;
	my $class = ref($self) || $self;
	my %methods = ();
	foreach my $class (Class::ISA::self_and_super_path($class)) {
		while (my ($name, $info) = each %{$self->_Tests->{$class}}) {
			$methods{$name} = 1 if $info->{$type};
		};
	};
	return(sort keys %methods);
};



=item teardown_methods

=item test_methods

=item setup_methods

  @methods = $Tests->setup_methods
  @methods = CLASS->setup_methods

  @methods = $Tests->test_methods
  @methods = CLASS->test_methods

  @methods = $Tests->teardown_methods
  @methods = CLASS->teardown_methods

Return a list of the names of the setup/test/teardown methods for the given class/object in the order they will be executed by L</"runtests">. See L</"runtests"> for more details.

These methods are useful in debugging test classes. For example, the following method will print out the running order of all the setup, test and teardown methods in a test class.

  sub show_running_order {
      my $class = shift;
      my @setup = $class->setup_methods;
      my @teardown = $class->teardown_methods;
      foreach my $method ($class->test_methods) {
          $class->builder->diag("@setup $method @teardown");
      };
  };

=cut

sub teardown_methods	{ shift->_get_methods('teardown') };
sub setup_methods		{ shift->_get_methods('setup') };
sub test_methods		{ shift->_get_methods('tests') };



=item total_num_tests

  $n = $Tests->total_num_tests
  $n = $Tests->total_num_tests($method_name)
  $n = CLASS->total_num_tests
  $n = CLASS->total_num_tests($method_name)

Return the total number of tests that the named setup/test/teardown method should run for the given class/object. If the method name is not specified L</"current_method"> is used.

If the method has an undetermined number of tests, then the string C<no_plan> is returned.

For example in:

  package Base::Test; 
  use base qw(Test::Class);
  ...  
  sub test_fields : Test {
      my $self = shift;
      is($self->{object}->field1, 'foo', 'field1 access ok');
  };

  package Object::Test; 
  use base qw(Base::Test);
  ...
  sub test_fields : Test(+1) {
      my $self = shift;
      $self->SUPER::test_fields;
      is($self->{object}->field2, 'bar', 'field2 access ok');
  };

The C<total_num_tests> of C<test_fields> in C<Object::Test> is C<2>.

=cut

sub total_num_tests {
	my ($self, $method) = @_;
	my $class = ref($self) || $self;
	$method ||= $Current_method;
	croak "you must supply a method name" unless $method;
	my $total_num_tests = undef;
	foreach my $class (Class::ISA::self_and_super_path($class)) {
		next unless exists $self->_Tests->{$class}->{$method};
		my $num_tests = $self->_Tests->{$class}->{$method}->{num_tests};
		return($num_tests) if ($num_tests eq "no_plan");
		$total_num_tests += $num_tests;
		last unless $num_tests =~ m/^\+/
	};
	croak "$class->$method is not a test"
			unless defined($total_num_tests);
	return($total_num_tests);
};



sub _find_calling_test_class {
	my $level = 0;
	while (my $class = caller(++$level)) {
		next if $class eq "Test::Class";
		return($class) if $class->isa('Test::Class');
	}; 
	return(undef);
};



=item num_method_tests

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

The advantage of setting the number of tests at object creation time, rather than using a test method without a plan, is that the number of expected tests can be determined before testing begins. This allows better diagnostics from L</"runtests">, L<Test::Builder> and L<Test::Harness>.

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
	my $info = $self->_Tests->{$class}->{$method};
	croak "$method is not a test method of class $class" unless $info;
	if (defined($n)) {
		croak "$n is not a valid number of tests" 
				unless _is_num_tests($n);
		$info->{num_tests} = $n;
	};
	return($info->{num_tests});
};



=item num_tests

  $n = $Tests->num_tests
  $Tests->num_tests($n)
  $n = CLASS->num_tests
  CLASS->num_tests($n)

Set or return the number of expected tests associated with the currently running test method. This is the same as calling L</"num_method_tests"> with a method name of L</"current_method">.

For example:

  sub txt_files_readable : Test(no_plan) {
      my $self = shift;
      my @files = <*.txt>;
      $self->num_tests(scalar(@files));
      ok(-r $_, "$_ readable") foreach (@files);
  };

Setting the number of expected tests at runtime, rather than just having a C<no_plan> test method, allows L</"runtests"> to display appropriate diagnostic messages if the method runs a different number of tests.

=cut

sub num_tests {
	my ($self, $n) = @_;
	croak "num_tests need to be called within a test method"
			unless defined $Current_method;
	return($self->num_method_tests($Current_method, $n));
};



=item expected_tests

  $n = $Tests->expected_tests
  $n = CLASS->expected_tests
  $n = $Tests->expected_tests(TEST, ...)
  $n = CLASS->expected_tests(TEST, ...)

Returns the total number of tests that L</"runtests"> will run on the specified class/object. This includes tests run by any setup and teardown methods.

Will return C<no_plan> if the exact number of tests is undetermined (i.e. if any setup, test or teardown method has an undetermined number of tests).

The C<expected_tests> of an object after L</"runtests"> has been executed will include any runtime changes to the expected number of tests made by L</"num_tests"> or L</"num_method_tests">.

C<expected_tests> can also take an optional list of test objects, test classes and integers. In this case the result is the total number of expected tests for all the test/object classes (including the one the method was applied to) plus any integer values.

C<expected_tests> is useful when you're integrating one or more test classes into a more traditional test script, for example:

  use Test::More;
  use My::Test::Class;

  plan tests => My::Test::Class->expected_tests_of(+2);

  ok(whatever, 'a test');
  ok(whatever, 'another test');
  My::Test::Class->runtests;

=cut

sub _expected_tests {
	my $self = shift;
	my $expected_tests = 0;
	my $pre_post_tests = 0;
	foreach my $method ($self->setup_methods, $self->teardown_methods) {
		my $num_tests = $self->total_num_tests($method);
		return($num_tests) if $num_tests eq "no_plan";
		$pre_post_tests += $num_tests;
	};
	foreach my $method ($self->test_methods) {
		my $num_tests = $self->total_num_tests($method);
		return($num_tests) if $num_tests eq "no_plan";
		$expected_tests += $num_tests + $pre_post_tests;
	};
	return($expected_tests);
};


sub expected_tests {
	my $total = 0;
	foreach my $test (@_) {
		if (UNIVERSAL::isa($test, 'Test::Class')) {
			my $n = $test->_expected_tests;
			return($n) if $n eq 'no_plan';
			$total += $n;
		} elsif ($test =~ m/^\d+$/) {
			$total += $test;
		} else {
			croak "$test is not a Test::Class";
		};
	};
	return($total);
};


sub _show_header {
	my $self = shift;
	my $expected_tests = shift;
	if ($expected_tests eq "no_plan") {
		$Builder->no_plan;
	} else {
		$Builder->expected_tests($expected_tests);
	};
};


sub _run_method {
	my ($self, $test_method) = @_;
	my $start_num = $Builder->current_test;
	my $skip_reason = eval {$self->$test_method};
	my $exception = $@;
	chomp($exception) if $exception;
	my $num_tests_done = $Builder->current_test - $start_num;
	my $num_tests = $self->total_num_tests($test_method);
	$num_tests = $num_tests_done if $num_tests eq "no_plan";
	if ($num_tests_done == $num_tests) {
		unless ($exception eq '') {
			$Builder->diag("$test_method died after test(s) with: $exception");
		};
	} elsif ($num_tests_done > $num_tests) {
		$Builder->diag("expected $num_tests test(s) in $test_method, $num_tests_done completed\n");
	} else {
		until (($Builder->current_test - $start_num) >= $num_tests) {
			if ($exception ne '') {
				local $Test::Builder::Level = 2;
				$Builder->ok(0, $exception);
			} else {
				$Builder->skip($skip_reason || $test_method);
			};
		};
		
	};
};


sub _all_ok {
	foreach my $test ($Builder->summary) {
		return(0) unless $test;
	};
	return(1);
};



=item runtests

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

  sub test_open : Test(2) {
      my $object = Object->new;
      isa_ok($object, "Object") or die("could not create object");
      is($object->open, "open worked");
  };

Would produce something like this if the first test failed:

  not ok 1 - The object isa Object
  #     Failed test (t/runtests_die.t at line 15)
  #     The object isn't defined
  not ok 2 - could not create object
  #     Failed test (t/runtests_die.t at line 27)

If a method returns before the expected number of tests for that method have run, all remaining tests for that method are skipped. The return value is used as the reason for skipping the tests, or the method name of the test if the return value is false. For example:

  sub darwin_only : Test {
      return("darwin only test") unless $^O eq "darwin";
      ok(-w "/Library", "/Library writable") 
  };

Will produce:

  ok 1 # skip darwin only test

unless the test is run on the darwin OS.

Just like L</"expected_tests">, C<runtests> can take an optional list of test object/classes and integers. All of the test object/classes are run. Any integers are added to the total number of tests shown in the test header output by C<runtests>. 

For example, you can run all the tests in test classes A, B and C, plus one additional normal test by doing:

    Test::Class->runtests(qw(A B C), +1);
    ok(1==1, 'non class test');

If the environment variable C<TEST_VERBOSE> is set C<runtests> will display the name of each test method before it runs.

=cut

sub runtests {
	my @tests = map {(ref($_) || $_ =~ m/^\d+$/) ? $_ : $_->new} @_;
	foreach my $test (@tests) {
		next if $test =~ m/^\d+$/;
		croak ("$test is not a Test::Class") 
				unless UNIVERSAL::isa($test, "Test::Class");
		my @setup = $test->setup_methods;
		my @teardown = $test->teardown_methods;
		foreach my $test_method ($test->test_methods) { 
			local $Current_method = $test_method;
			$Builder->diag(ref($test) . "->$test_method") 
					if $ENV{TEST_VERBOSE};
			foreach my $method (@setup, $test_method, @teardown) {
				$test->_show_header(Test::Class->expected_tests(@tests))
					if !$test->_has_plan 
					&& $test->total_num_tests($method) ne '0';
				$test->_run_method($method) 
			};
		};
	};
	return(Test::Class->_all_ok);	
};


=back

=head1 BUGS

If you have:

=over 4

=item *

declared a C<no_plan> test with Test::Builder (or any of its friends)

=item *

a Test::Class with a defined number of tests

=item *

call L</"runtests"> before running any other tests

=back

then L</"runtests"> will incorrectly displays a duplicate header line. 

If you find any bugs please let me know by e-mail, or report the problem with <http://rt.cpan.org/>.


=head1 TO DO

The following things are on my to do list, but probably won't get done until somebody pokes me - so if you want it done poke away (or write a patch :-)

=over 4

=item *

There is no way of running individual test methods.

=item *

There is no way of mapping tests passed or failed to the methods that ran them. 

=item *

There should  be a nice tutorial that demonstrates the features in a vaguely coherent manner (this one is mostly done).

=item *

Should probably have some examples to show why setting the number of tests is better than using C<no_plan>.

=item *

The example code and documentation is not as clear as it should be. Things like the JUnit commentary should probably be split to a separate file.

=item *

Have the option of making test methods fail after the first failing test, for those who prefer that style.

=item *

Have the test name of C<Test::Builder::ok> default to L</"current_method">.

=item *

Think about making it work without attributes.

=back

If you think this module should do something that it doesn't (or does something that it shouldn't) please let me know.


=head1 ACKNOWLEGEMENTS

This is yet another implementation of the ideas from Kent Beck's Testing Framework paper. 

This module wouldn't be possible without the excellent L<Test::Builder>. Thanks to chromatic <chromatic@wgz.org> and Michael G Schwern <schwern@pobox.com> for creating such a useful module.


=head1 AUTHOR

Adrian Howard <adrianh@quietstars.com>

If you can spare the time, please drop me a line if you find this module useful.


=head1 SEE ALSO

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
