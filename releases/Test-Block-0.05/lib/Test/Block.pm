package Test::Block;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT_OK = qw($Plan);

use Carp;
use Test::Builder;
use overload 
    q{""} => \&remaining,
    q{+0} => \&remaining, 
    fallback => 1;

our $VERSION = '0.05';


my $Last_test_in_previous_block = 0;
my $Active_block_count = 0;


my $Test_builder = Test::Builder->new;
sub builder { $Test_builder };


my $Block_count = 0;
sub block_count { $Block_count };


sub plan {
    my $class = shift;
    my ($num_tests, $name) = (pop, pop);
    croak "need # tests" unless $num_tests && $num_tests =~ /^\d+/;
    $Block_count++;
    $Active_block_count++;
    return bless {
        name            => $name || $Block_count,
        expected_tests  => $num_tests,
        initial_test    => $Test_builder->current_test,
    }, $class;
};


sub _tests_run_in_block {
    my $self = shift;
    return $Test_builder->current_test - $self->{initial_test}
};


sub remaining { 
    my $self = shift;
    return $self->{expected_tests} - _tests_run_in_block($self);
};


sub DESTROY {
    my $self = shift;
    $Active_block_count--;
    $Last_test_in_previous_block = $Test_builder->current_test;
    my $expected = $self->{expected_tests};
    my $name = $self->{name};
    my $tests_ran = _tests_run_in_block($self);
    $Test_builder->ok(
        0, 
        "block $name expected $expected test(s) and ran $tests_ran"
    ) unless $tests_ran == $expected;
};


my $All_tests_in_block = 1;
sub all_in_block { 
    return unless $All_tests_in_block;
    return 1 if $Active_block_count > 0;
    $All_tests_in_block = 
        $Last_test_in_previous_block == $Test_builder->current_test;
    return $All_tests_in_block
};


{
    package Test::Block::Plan;
    use Tie::Scalar;
    use base qw(Tie::StdScalar);
    
    sub STORE {
        my ($self, $plan) = @_;
        if ( defined($plan) && !UNIVERSAL::isa($plan, 'Test::Block') 
        ) {
            $plan = Test::Block->plan( ref($plan) ? %$plan : $plan );
        };
        $self->SUPER::STORE($plan);
    }
}

our $Plan;
tie $Plan, 'Test::Block::Plan';

1;
__END__

=head1 NAME

Test::Block - specify fine granularity test plans

=head1 SYNOPSIS

  use Test::More 'no_plan';
  use Test::Block qw($Plan);

  {
      # This block should run exactly two tests
      local $Plan = 2;
      pass 'first test';
      # oops. forgot second test
  };

  SKIP: {
      local $Plan = 3;
      pass('first test in second block');
      skip "skip remaining tests" => $Plan;
  };

  ok( Test::Block->all_in_block, 'all test run in blocks' );
  is( Test::Block->block_count, 2, 'two blocks ran' );

  # This produces...
  
  ok 1 - first test
  not ok 2 - block expected 2 test(s) and ran 1
  #     Failed test (foo.pl at line 6)
  ok 3 - first test in second block
  ok 4 # skip skip remaining tests
  ok 5 # skip skip remaining tests
  ok 6 - all test run in blocks
  ok 7 - two blocks ran
  1..7
  # Looks like you failed 1 tests of 7.


=head1 DESCRIPTION

This module allows you to specify the number of expected tests at a finer level of granularity than an entire test script. It is built with L<Test::Builder> and plays happily with L<Test::More> and friends.

If you are not already familiar with L<Test::More> now would be the time to go take a look.


=head2 Creating test blocks

Test::Block supplies a special variable C<$Plan> that you can localize to specify the number of tests in a block like this:

    use Test::More 'no_plan';
    use Test::Block qw($Plan);
    
    {
        local $Plan = 2;
        pass('first test');
        pass('second test');
    };
    
=head2 What if the block runs a different number of tests?
    
If a block doesn't run the number of tests specified in C<$Plan> then Test::Block will automatically produce a failing test. For example:

    {
        local $Plan = 2;
        pass('first test');
        # oops - forgot second test
    };

will output

    ok 1 - first test
    not ok 2 - block 1 expected 2 test(s) and ran 1

=head2 Tracking the number of remaining tests

During the execution of a block C<$Plan> will contain the number of remaining tests that are expected to run so:

    {
        local $Plan = 2;
        diag "$Plan tests to run";
        pass('first test');
        diag "$Plan tests to run";
        pass('second test');
        diag "$Plan tests to run";
    };

will produce

    # 2 tests to run
    ok 1 - first test
    # 1 tests to run
    ok 2 - second test
    # 0 tests to run

This can make skip blocks easier to write and maintain, for example:

    SKIP: {
        local $Plan = 5;
        pass('first test');
        pass('second test');
        skip "debug tests" => $Plan unless DEBUG > 0;
        pass('third test');
        pass('fourth test');
        skip "high level debug tests" => $Plan unless DEBUG > 2;
        pass('fifth test');
    };


=head2 Named blocks

To make debugging easier you can give your blocks an optional name like this:

    {
        local $Plan = { example => 2 };
        pass('first test');
        # oops - forgot second test
    };

which would output

    ok 1 - first test
    not ok 2 - block example expected 2 test(s) and ran 1


=head2 Test::Block objects

The C<$Plan> is implemented using a tied variable that stores and retrieves Test::Block objects. If you want to avoid the tied interface you can use Test::Block objects directly.

=over 4

=item B<plan>

  # create a block expecting 4 tests
  my $block = Test::Block->plan(4);

  # create a named block with two tests
  my $block = Test::Block->plan('test name' => 2);

You create Test::Block objects with the C<plan> method. When the object is destroyed it outputs a failing test if the expected number of tests have not run. 


=item B<remaining>

You can find out the number of remaining tests in the block by calling the C<remaining> method on the object. 

Test::Block objects overload C<""> and C<0+> to return the result of the remaining method.


=item B<builder>

Returns L<Test::Builder> object used by Test::Block. For example:

  Test::Block->builder->skip('skip a test');

See L<Test::Builder> for more information.


=item B<block_count>

A class method that returns the number of blocks that have been created. You can use this to check that the expected number of blocks have run by doing something like:

  is( Test::Block->block_count, 5, 'five blocks run' );

at the end of your test script.


=item B<all_in_block>

Returns true if all tests so far run have been inside the scope of a Test::Block object.

  ok( Test::Block->all_in_block, 'all tests run in blocks' );

=back


=head1 BUGS

None known at the time of writing. 

If you find any please let me know by e-mail, or report the problem with L<http://rt.cpan.org/>.


=head1 TO DO

Nothing at the time of writing.

If you think this module should do something that it doesn't do at the moment please let me know.


=head1 ACKNOWLEGEMENTS

Thanks to chromatic and Michael G Schwern for the excellent Test::Builder, without which this module wouldn't be possible.

Thanks to Michael G Schwern and Tony Bowden for the mails on perl-qa@perl.org that sparked the idea for this module. Thanks to Fergal Daly for suggesting named blocks. Thanks to Michael G Schwern for suggesting $Plan.


=head1 AUTHOR

Adrian Howard <adrianh@quietstars.com>

If you can spare the time, please drop me a line if you find this module useful.


=head1 SEE ALSO

=over 4

=item L<Test::Builder>

Support module for building test libraries.

=item L<Test::Simple> & L<Test::More>

Basic utilities for writing tests.

=item L<http://qa.perl.org/test-modules.html>

Overview of some of the many testing modules available on CPAN.

=back


=head1 LICENCE

Copyright 2003-2004 Adrian Howard, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


1;
