#!/usr/bin/perl 

use strict;
use warnings;
use Test::More tests => 13;
use Test::Class::Load 't/lib';

ok exists $INC{'Tests/Foo.pm'},
  'Classes in top level directories should be loaded';
ok exists $INC{'Tests/Foo/Bar.pm'}, '... as should tests in subdirectories';
is +Tests::Foo->foo, 'ooF::stseT',
  '... and the methods should work correctly';
is +Tests::Foo::Bar->foo, 'ooF::stseT',
  '... even if they are called from subclasses';
is +Tests::Foo::Bar->bar, 'raB::ooF::stseT',
  '... or they have their own methods';

delete $INC{'Tests/Foo.pm'};
delete $INC{'Tests/Foo/Bar.pm'};
delete $INC{'Test/Class/Load.pm'};

$SIG{__WARN__} = sub {
    warn @_
      unless $_[0] =~ /^Subroutine \w+ redefined/;
};
eval "use Test::Class::Load qw(t/lib t/tlib)";
ok !$@, 'Trying to load multiple lib paths should succeed';

ok exists $INC{'Tests/Foo.pm'},
  'Top level directories should be loaded even with multiple libs';
ok exists $INC{'Tests/Foo/Bar.pm'}, '... as should tests in subdirectories';
is +Tests::Foo->foo, 'ooF::stseT',
  '... and the methods should work correctly';
is +Tests::Foo::Bar->foo, 'ooF::stseT',
  '... even if they are called from subclasses';
is +Tests::Foo::Bar->bar, 'raB::ooF::stseT',
  '... or they have their own methods';
ok exists $INC{'MyTest/Baz.pm'}, 'And secondary libs should be loaded';
is +MyTest::Baz->baz, 23,
  '... and their methods should also work correctly';

