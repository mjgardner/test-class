package TestClassLoadSubclass;

use strict;
use warnings;
use base qw(Test::Class::Load);

# Overriding this selects what test classes
# are considered by T::C::Load
sub is_test_class {
    my ($class, $file, $dir) = @_;
    # Get only "good" classes
    if ($file =~ m{Good}) {
        return 1;
    }
    return;
}

1;
