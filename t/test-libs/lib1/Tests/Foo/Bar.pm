package Tests::Foo::Bar;

use strict;
use warnings;

use base 'Tests::Foo';

sub bar { scalar reverse __PACKAGE__ }

1;

