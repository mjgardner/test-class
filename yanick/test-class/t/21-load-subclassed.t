#!/usr/bin/perl 

use strict;
use warnings;
use Test::More tests => 7;
use lib './t';
use TestClassLoadSubclass 't/test-libs/lib3';

ok exists $INC{'Tests/Good1.pm'},
  'Classes in top level directories should be loaded';

ok exists $INC{'Tests/Subdir/Good3.pm'},
  '... as should classes in subdirectories';

ok !exists $INC{'Tests/Bad1.pm'},
  'Filtered out classes in top level directories should *not* be loaded';

ok !exists $INC{'Tests/Subdir/Bad2.pm'},
  'Filtered out classes in subdirectories should *not* be loaded';

for my $class (qw(Tests::Good1 Tests::Good2 Tests::Subdir::Good3)) {
    is $class->ok(), $class, 'Class ' . $class . ' method work as expected'
}

