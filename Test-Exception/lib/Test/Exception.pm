#! /usr/bin/perl -w

package Test::Exception;
use 5.005;
use strict;
use Test::Builder;
use Sub::Uplevel;
use base qw(Exporter);

use vars qw($VERSION @EXPORT @EXPORT_OK);

$VERSION = '0.20';
@EXPORT = qw(dies_ok lives_ok throws_ok lives_and);

my $Tester = Test::Builder->new;

sub import {
    my $self = shift;
    if (@_) {
        my $package = caller;
        $Tester->exported_to($package);
        $Tester->plan(@_);
    };
    $self->export_to_level(1, $self, $_) foreach @EXPORT;
}

=head1 NAME

Test::Exception - Test exception based code

=head1 SYNOPSIS

  use Test::More tests => 5;
  use Test::Exception;

  # or if you don't need Test::More

  use Test::Exception tests => 5;

  # then...

  # Check that something died
  dies_ok {$foo->method1} 'expecting to die';

  # Check that something did not die
  lives_ok {$foo->method2} 'expecting to live';

  # Check that the stringified exception matches given regex
  throws_ok {$foo->method3} qr/division by zero/, 'zero caught okay';

  # Check an exception of the given class (or subclass) is thrown
  throws_ok {$foo->method4} 'Error::Simple', 'simple error thrown';

  # Check that a test runs without an exception
  lives_and {is $foo->method, 42} 'method is 42';

=head1 DESCRIPTION

This module provides a few convenience methods for testing exception based code. It is built with L<Test::Builder> and plays happily with L<Test::More> and friends.

If you are not already familiar with L<Test::More> now would be the time to go take a look.

You can specify the test plan when you C<use Test::Exception> in the same way as C<use Test::More>. See L<Test::More> for details.

=cut


sub _try_as_caller {
    my $coderef = shift;
    eval { uplevel 3, $coderef };
    return $@;
};


sub _is_exception {
    my $exception = shift;
    ref($exception) || $exception ne '';
};


sub _exception_as_string {
    my ($prefix, $exception) = @_;
    return "$prefix undef" unless defined($exception);
    return "$prefix normal exit" unless _is_exception($exception);
    my $class = ref($exception);
    $exception = "$class ($exception)" 
            if $class && "$exception" !~ m/^\Q$class/;
    chomp($exception);
    return("$prefix $exception");
};


=over 4

=item B<dies_ok>

Checks that a piece of code dies, rather than returning normally. For example:

    sub div {
        my ($a, $b) = @_;
        return( $a / $b );
    };

    dies_ok { div(1, 0) } 'divide by zero detected';

A true value is returned if the test succeeds, false otherwise. On exit $@ is guaranteed to be the cause of death (if any).

The test name is optional, but recommended. 

=cut


sub dies_ok (&;$) {
    my ($coderef, $name) = @_;
    my $exception = _try_as_caller($coderef);
    my $ok = $Tester->ok( _is_exception($exception), $name );
    $@ = $exception;
    return($ok);
}


=item B<lives_ok>

Checks that a piece of code exits normally, and doesn't die. For example:

    sub read_file {
        my $file = shift;
        local $/ = undef;
        open(FILE, $file) or die "open failed ($!)\n";
        $file = <FILE>;
        close(FILE);
        return($file);
    };

    my $file;
    lives_ok { $file = read_file('test.txt') } 'file read';

Should a lives_ok() test fail it produces appropriate diagnostic messages. For example:

    not ok 1 - file read
    #     Failed test (test.t at line 15)
    # died: open failed (No such file or directory)

A true value is returned if the test succeeds, false otherwise. On exit $@ is guaranteed to be the cause of death (if any).

The test name is optional, but recommended. 

=cut

sub lives_ok (&;$) {
    my ($coderef, $name) = @_;
    my $exception = _try_as_caller($coderef);
    my $ok = $Tester->ok(! _is_exception($exception), $name)
        || $Tester->diag(_exception_as_string("died:", $exception));
    $@ = $exception;
    return($ok);
}


=item B<throws_ok>

Tests to see that a specific exception is thrown. throws_ok() has two forms: 

  throws_ok BLOCK REGEX, TEST_NAME
  throws_ok BLOCK CLASS, TEST_NAME

In the first form the test passes if the stringified exception matches the give regular expression. For example:

    throws_ok { 
        read_file('test.txt') 
    } qr/No such file/, 'no file';

If your perl does not support C<qr//> you can also pass a regex-like string, for example:

    throws_ok { 
        read_file('/etc/kcpassword') 
    } '/Permission denied/', 'no permissions';

The second form of throws_ok() test passes if the exception is of the same class as the one supplied, or a subclass of that class. For example:

    throws_ok {$foo->bar} "Error::Simple", 'simple error';

Will only pass if the C<bar> method throws an Error::Simple exception, or a subclass of an Error::Simple exception.

You can get the same effect by passing an instance of the exception you want to look for. The following is equivalent to the previous example:

    my $SIMPLE = Error::Simple->new();
    throws_ok {$foo->bar} $SIMPLE, 'simple error';

Should a throws_ok() test fail it produces appropriate diagnostic messages. For example:

    not ok 3 - simple error
    #     Failed test (test.t at line 48)
    # expecting: Error::Simple exception
    # found: normal exit

A true value is returned if the test succeeds, false otherwise. On exit $@ is guaranteed to be the cause of death (if any).

The test name is optional. If no test name is given a description of the exception being checked for is used. 

=cut


sub throws_ok (&$;$) {
    my ($coderef, $expecting, $name) = @_;
    $name ||= _exception_as_string("threw", $expecting);
    my $exception = _try_as_caller($coderef);
    my $regex = $Tester->maybe_regex($expecting);
    my $ok = $regex ? ($exception =~ m/$regex/) 
            : UNIVERSAL::isa($exception, ref($expecting) || $expecting);
    $Tester->ok($ok, $name);
    unless ($ok) {
        $Tester->diag( _exception_as_string("expecting:", $expecting) );
        $Tester->diag( _exception_as_string("found:", $exception) );
    };
    $@ = $exception;
    return($ok);
};


=item B<lives_and>

Run a test that may throw an exception. For example, instead of doing:

    my $file;
    lives_ok { $file = read_file('answer.txt') } 'read_file worked';
    is $file, "42\n", 'answer was 42';

You can use lives_and() like this:

    lives_and { is read_file('answer.txt'), "42\n" } 'answer is 42';

Which is the same as doing

    is read_file('answer.txt'), "42\n", 'answer is 42';

unless C<read_file('answer.txt')> dies, in which case you get the same kind of error as lives_ok()

    not ok 1 - answer is 42
    #     Failed test (test.t at line 15)
    # died: open failed (No such file or directory)

A true value is returned if the test succeeds, false otherwise. On exit $@ is guaranteed to be the cause of death (if any).

The test name is optional, but recommended.

=cut

sub lives_and (&$) {
    my ($test, $name) = @_;
    {
        local $Test::Builder::Level = $Test::Builder::Level+1;
        my $ok = \&Test::Builder::ok;
        no warnings;
        local *Test::Builder::ok = sub {
            $_[2] = $name unless defined $_[2];
            $ok->(@_);
        };
        use warnings;
        eval { $test->() } and return 1;
    };
    my $exception = $@;
    if (_is_exception($exception)) {
        $Tester->ok(0, $name);
        $Tester->diag( _exception_as_string("died:", $exception) );
    };
    $@ = $exception;
    return;
}

=back


=head1 BUGS

None known at the time of writing. 

If you find any please let me know by e-mail, or report the problem with L<http://rt.cpan.org/>.


=head1 TO DO

Nothing at the time of writing.

If you think this module should do something that it doesn't do at the moment please let me know.


=head1 ACKNOWLEGEMENTS

Thanks to chromatic and Michael G Schwern for the excellent Test::Builder, without which this module wouldn't be possible.

Thanks to Michael G Schwern, Mark Fowler, Janek Schleicher, chromatic, Mark Fowler, Peter Scott, Aristotle and Andy Lester for suggestions, bug reports and patches.


=head1 AUTHOR

Adrian Howard <adrianh@quietstars.com>

If you can spare the time, please drop me a line if you find this module useful.


=head1 SEE ALSO

=over 4

=item L<Test::Builder>

Support module for building test libraries.

=item L<Test::Simple> & L<Test::More>

Basic utilities for writing tests.

=item L<Test::Warn> & L<Test::NoWarnings>

Modules to help test warnings.

=item L<http://qa.perl.org/test-modules.html>

Overview of some of the many testing modules available on CPAN.

=back


=head1 LICENCE

Copyright 2002-2004 Adrian Howard, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
