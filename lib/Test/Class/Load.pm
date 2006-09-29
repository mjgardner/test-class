package Test::Class::Load;

use warnings;
use strict;
use Test::Class;

=head1 NAME

Test::Class::Load - Load C<Test::Class> classes automatically.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

 use Test::Class::Load qw(t/tests t/lib);
 Test::Class->runtests;

=head1 EXPORT

None.

=head1 DESCRIPTION

C<Test::Class> typically uses a helper script to load the test classes.  It
often looks something like this:

 #!/usr/bin/perl -T

 use strict;
 use warnings;

 use lib 't/tests';

 use MyTest::Foo;
 use MyTest::Foo::Bar;
 use MyTest::Foo::Baz;

 Test::Class->runtests;

This causes a problem, though.  When you're writing a test class, it's easy to
forget to add it to the helper script.  Then you run your huge test suite and
see that all tests pass, even though you don't notice that it didn't run your
new test class.  Or you delete a test class and you forget to remove it from
the helper script.

C<Test::Class::Load> automatically finds and loads your test classes for you.
There is no longer a need to list them individually.

=head1 BASIC USAGE

Using C<Test::More::Load> is as simple as this:

 #!/usr/bin/perl -T

 use strict;
 use warnings;

 use Test::Class::Load 't/tests';

 Test::Class->runtests;
 
That will search through all files in the C<t/tests> directory and
automatically load anything which ends in C<.pm>.  You should only put test
classes in those directories.

If you have test classes in more than one directory, that's OK. Just list all
of them in the import list.

 use Test::Class::Load qw<
   t/customer
   t/order
   t/inventory
 >;
 Test::Class->runtests;

=head1 ADVANCED USAGE

One problem with this style of testing is that you run I<all> of the tests
every time you need to test something.  If you want to run only one test
class, it's problematic.  The easy way to do this is to change your helper
script by deleting the C<runtests> call:
 
 #!/usr/bin/perl -T

 use strict;
 use warnings;

 use Test::Class::Load 't/tests';

Then, just make sure that all of your test classes inherit from your own base
class which runs the tests for you.  It might looks something like this:

 package My::Test::Class;
 
 use strict;
 use warnings;

 use base 'Test::Class';

 INIT { Test::Class->runtests } # here's the magic!

 1;

Then you can run an individual test class by using the C<prove> utility, tell
it the directory of the test classes and the name of the test package you wish
to run:

 prove -lv -It/tests Some::Test::Class

You can even automate this by binding it to a key in C<vim>:
    
 noremap ,t  :!prove -lv -It/tests %<CR>

Then you can just type C<,t> ('comma', 'tee') and it will run the tests for
your test class or the tests for your test script (if you're using a
traditional C<Test::More> style script).

Of course, you can still run your helper script with C<prove>, C<make test> or
C<./Build test> to run all of your test classes.

If you do that, you'll have to make sure that the C<-I> switches point to your
test class directories.

=cut

use strict;
use File::Find;
use File::Spec;

my %dirs;

sub _load {
    my ( $file, $dir ) = @_;
    $file =~ s/\.pm$// || return;    # we only care about .pm files
    $file =~ s/^$dir//;
    my $_package = join '::' => grep $_ => File::Spec->splitdir($file);

    # untaint that puppy!
    my ($package) = $_package =~ /^([[:word:]]+(?:::[[:word:]]+)*)$/;
    $dirs{$dir} = 1;
    unshift @INC => $dir;
    eval "require $package"; ## no critic
    die $@ if $@;
    return $package;
}

sub import {
    shift;
    foreach (@_) {
        my $dir = $_;    # avoid the 'modification of read-only value' problem
        $dir = File::Spec->catdir( split '/', $dir );
        find(
            {   no_chdir => 1,
                wanted   => sub { _load( $File::Find::name, $dir ) },
            },
            $dir
        );
    }
}

=head1 SECURITY

C<Test::Class::Load> is taint safe.  Because we're reading the class names
from the directory structure, they're marked as tainted when running under
taint mode.  We use the following ultra-paranoid bit of code to untaint them.
Please file a bug report if this is too restrictive.

 my ($package) = $_package =~ /^([[:word:]]+(?:::[[:word:]]+)*)$/;

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-class-load@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-Load>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to David Wheeler for the idea and Adrian Howard for C<Test::Class>.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
