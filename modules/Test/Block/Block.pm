package Test::Block;
use base qw(Exporter);
use strict;
use warnings;
use Carp;
use Test::Builder;
use overload q{""} => \&remaining, q{+0} => \&remaining, fallback => 1;

our $VERSION = '0.05';

our @EXPORT_OK = qw($Plan);

# use Test:Block blocks => 3, tests => 9, '$Plan';

my $Test = Test::Builder->new;
sub builder { $Test };

my $Expected_blocks;

sub import {
	my $self = shift;
	my @import;
	my @plan;
	while (@_) {
		my $next = shift;
		if ( $next eq 'blocks' ) {
			croak "need # blocks in import"
					unless @_ && $_[0] =~ m/^\d+/;
			$Expected_blocks = shift;
		} elseif (grep {$next eq $_} @EXPORT_OK) {
			push @import, $next;
		} else {
			push @plan, $next;
		};
	};
	$self->SUPER::import( @import );
	$Test->plan(@plan);
};


my $Block_count = 0;
sub block_count { $Block_count };

my $Last_test = 0;
my $Active_blocks = 0;
my $All_tests_in_block = 1;

sub all_in_block { 
	return unless $All_tests_in_block;
	return 1 if $Active_blocks;
	$All_tests_in_block = $Last_test == $Test->current_test;
};

sub plan {
	my $class = shift;
	unshift @_, "tests" if @_ == 1;
	my %param = @_;
	croak "need # tests" if $param{tests} && $param{tests} !~ /^\d+/;
	$Active_blocks++;
	bless {
		name => $param{name},
		expected_tests => $param{tests},
		initial_test => $Test->current_test,
	}, $class;
};

sub _ran { $Test->current_test - shift->{initial_test} };

sub remaining { 
	my $self = shift;
	$self->{expected_tests} - _ran($self);
};

sub DESTROY {
	my $self = shift;
	return unless my $expected = $self->{expected_tests};
	my $ran = _ran($self);
	my $name = defined $self->{name} 
		? "block '$self->{name}'" : "block";
	$Test->ok(0, "$name expected $expected test(s) and ran $ran")
		unless $ran == $expected;
	$Active_blocks--;
	$Block_count++;
	$Last_test = $Test->current_test;
};

{
	package Test::Block::Plan;
	use Tie::Scalar;
	use base qw(Tie::StdScalar);
	
	sub STORE {
		my ($self, $plan) = @_;
		if ( defined($plan) && !UNIVERSAL::isa($plan, 'Test::Block') ) {
			$plan = Test::Block->plan( ref($plan) ? %$plan : $plan );
		};
		$self->SUPER::STORE($plan);
	};
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
      # and is named 'foo'
      local $Plan = { tests => 2, name => 'foo' };
      pass 'first test in first block';
      # oops. forgot second test
  };

  SKIP: {
      # This block should run exactly three tests 
      local $Plan = 3;
      pass('first test in second block');
      skip "skip remaining tests", $Plan;
  };

  ok( Test::Block->all_in_block, 'all test run in blocks' );
  is( Test::Block->block_count, 2, 'two blocks ran' );

  # Above produces the following output.
  ok 1 - first test in first block
  not ok 2 - block 'foo' expected 2 test(s) and ran 1
  ok 3 - first test in second block
  ok 4 # skip skip remaining tests
  ok 5 # skip skip remaining tests
  ok 6 - all test run in blocks
  ok 7 - two blocks ran
  1..7


=head1 DESCRIPTION

This module allows you to specify the number of expected tests at a finer level of granuality than an entire test script. It is built with L<Test::Builder> and plays happily with L<Test::More> and friends.

If you are not already familiar with L<Test::More> now would be the time to go take a look.


=over 4

=item B<plan>

  # create a block expecting 4 tests
  my $block = Test::Block->plan(4);

  # create a named block with two tests
  my $block = Test::Block->plan(tests=>2, name=>'fribble');

You create Test::Block objects with the C<plan> method. When the object is destroyed it outputs a failing test if the expected number of tests have not run. For example doing:

  {
      my $block = Test::Block->plan(tests => 3, name => 'foo');
      ok(1);
      # oops - missed two tests out
  }

will produce

  ok 1
  not ok 2 - block 'foo' expected 3 test(s) and ran 1


=item B<$Test::Block::Plan>

C<$Test::Block::Plan> is a tied variable that allows you to easily create and localise Test::Block objects. Rather than doing:

  use Test::Block;
  {
      my $block = Test::Block->plan(tests => 3, name => 'foo');
      ...
  }
  {
      my $block = Test::Block->plan(4);
      ...
  }

you can do:

  use Test::Block qw($Plan);
  {
      local $Plan = {tests => 3, name => 'foo'};
      ...
  }
  {
      local $Plan = 4;
      ...
  }


=item B<remaining>

You can find out the number of remaining tests in the block by calling the C<remaining> method on the object. Doing:

  {
      my $block = Test::Block->plan(2);
      diag $block->remaining . " test(s) left";
      pass 'first test';
      diag $block->remaining . " test(s) left";
      pass 'second test';
      diag $block->remaining . " test(s) left";
  };

produces

  # 2 test(s) left
  ok 1 - first test
  # 1 test(s) left
  ok 2 - second test
  # 0 test(s) left
  1..2

Test::Block objects overload C<""> and C<0+> to return the result of the remaining method, so the previous example can be written as:

  {
      my $block = Test::Block->plan(2);
      diag "$block test(s) left";
      pass 'first test';
      diag "$block test(s) left";
      pass 'second test';
      diag "$block test(s) left";
  };

Combined with L<$Test::Block::Plan> it can make C<SKIP> blocks with multiple exit points much easier to manage, for example:

  SKIP: {
      local $Plan = 3;
      pass 'level 0 test';

      skip 'test level < 1' => $Plan if TEST_LEVEL < 1;
      pass 'level 1 test';

      skip 'test level < 2' => $Plan if TEST_LEVEL < 2;        
      pass 'level 2 test';
  };


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

Backend for building test libraries

=item L<Test::Simple> & L<Test::More>

Basic utilities for writing tests.

=item L<Test::Class>

Easily create test classes in an xUnit style. Test::Class allows you to specify the number of tests on a method-by-method basis.

=back


=head1 LICENCE

Copyright 2003 Adrian Howard, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
