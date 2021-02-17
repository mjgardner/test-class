use strict;
use warnings;
require 5.008001;
use ExtUtils::MakeMaker;

my $developer = -f '.gitignore';
ExtUtils::MakeMaker->VERSION(6.98) if $developer;

my %WriteMakefileArgs = (
    NAME                => 'Test::Class',
    VERSION_FROM        => 'lib/Test/Class.pm',
    ABSTRACT_FROM       => 'lib/Test/Class.pm',
    AUTHOR              => 'Adrian Howard <adrianh@quietstars.com>, Curtis "Ovid" Poe, <ovid at cpan.org>, Mark Morgan <makk384@gmail.com>',
    LICENSE             => 'perl_5',

    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            repository => {
                url => 'https://github.com/szabgab/test-class.git',
                web => 'https://github.com/szabgab/test-class',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/szabgab/test-class/issues',
            },
        },
        x_contributors => [ # manually added, from git shortlog -e -s -n
            'Adrian Howard <adrianh@quietstars.com>',
            'Karen Etheridge <ether@cpan.org>',
            'Curtis Poe <ovid@cpan.org>',
            'makk384 <makk384@gmail.com>',
            'Ricardo Signes <rjbs@cpan.org>',
            'Alexandr Ciornii <alexchorny@gmail.com>',
            'Tim Vroom <vroom@blockstackers.com>',
            'Matthew Horsfall <WolfSage@gmail.com>',
            'Michael G. Schwern <schwern@pobox.com>',
            'Chad Granum <exodist7@gmail.com>',
            'Peter Sergeant <pete@clueball.com>',
            'Sam Kington <github@illuminated.co.uk>',
            'Klaus S. Madsen <ksm@jobindex.dk>',
            'Zefram <zefram@fysh.org>',
            'Kent Fredric <kentfredric@gmail.com>',
        ],
        x_MailingList => 'http://lists.perl.org/list/perl-qa.html',
        x_IRC => 'irc://irc.perl.org/#perl-qa',
    },

    META_ADD => {
        'meta-spec' => { version => 2 },
        prereqs => {
            configure => {
                requires => {
                    'ExtUtils::MakeMaker' => '0',
                },
            },
            runtime => {
                requires => {
                    'perl'                  => '5.008001',
                    'Attribute::Handlers'   => '0.77',
                    'MRO::Compat'           => '0.11',
                    'Storable'              => '2.04',
                    'Test::Simple'          => '0.78',
                    'Test::Builder'         => '0.78',
                    'Test::Builder::Tester' => '1.02',
                    'Carp'                  => '0',
                    'File::Find'            => '0',
                    'File::Spec'            => '0',
                    'constant'              => '0',
                    'strict'                => '0',
                    'warnings'              => '0',
                    'Try::Tiny'             => '0',
                    'Module::Runtime'       => '0',
                },
            },
            test => {
                requires => {
                    'Test::Exception'       => '0.25',
                    'IO::File'              => '1.09',
                    'Test::More'            => '0.78',
                    'Fcntl'                 => '0',
                    'Test'                  => '0',
                    'base'                  => '0',
                    'overload'              => '0',
                },
            },
        },
    },
);

my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;

for (qw(configure build test runtime)) {
    my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
    next unless exists $WriteMakefileArgs{META_ADD}{prereqs}{$_}
             or exists $WriteMakefileArgs{$key};
    my $r = $WriteMakefileArgs{$key} = {
        %{$WriteMakefileArgs{META_ADD}{prereqs}{$_}{requires} || {}},
        %{delete $WriteMakefileArgs{$key} || {}},
    };
    defined $r->{$_} or delete $r->{$_} for keys %$r;
}

# dynamic prereqs get added here.

# 0.99 broke test_out with qr//
$WriteMakefileArgs{PREREQ_PM}{'Test::Builder'} = '1.001002'
    if eval { require Test::Builder; Test::Builder->VERSION eq '0.99' };

$WriteMakefileArgs{MIN_PERL_VERSION} = delete $WriteMakefileArgs{PREREQ_PM}{perl} || 0;

die 'attention developer: you need to do a sane meta merge here!'
    if keys %{$WriteMakefileArgs{BUILD_REQUIRES}};

$WriteMakefileArgs{BUILD_REQUIRES} = {
    %{$WriteMakefileArgs{BUILD_REQUIRES} || {}},
    %{delete $WriteMakefileArgs{TEST_REQUIRES}}
} if $eumm_version < 6.63_03;

$WriteMakefileArgs{PREREQ_PM} = {
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{delete $WriteMakefileArgs{BUILD_REQUIRES}}
} if $eumm_version < 6.55_01;

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    if $eumm_version < 6.51_03;

delete $WriteMakefileArgs{MIN_PERL_VERSION}
    if $eumm_version < 6.48;

delete @WriteMakefileArgs{qw(META_ADD META_MERGE)}
    if $eumm_version < 6.46;

delete $WriteMakefileArgs{LICENSE}
    if $eumm_version < 6.31;

WriteMakefile(%WriteMakefileArgs);

use Config;
system("$Config{bin}/pod2text $WriteMakefileArgs{VERSION_FROM} > README")
    if $developer
        and (not -e 'README' or (stat('README'))[9] < (stat($WriteMakefileArgs{VERSION_FROM}))[9]);
