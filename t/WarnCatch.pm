package t::WarnCatch;

my $warning;
$SIG{__WARN__} = sub { $warning = "@_" };

sub Caught { $warning }

1;
