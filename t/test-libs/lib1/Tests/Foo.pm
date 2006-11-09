package Tests::Foo;

use strict;
use warnings;

sub foo { scalar reverse __PACKAGE__ }

1;

