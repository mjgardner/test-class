use Module::Build;

use strict;
use warnings;

use Test::Builder;

# 0.99 broke test_out with qr//
my $tb_v = Test::Builder->VERSION eq '0.99' ? '1.001002' : '0.78';

my $build = Module::Build->new(
    module_name => 'Test::Class',
    license     => 'perl',
    requires    => {
        'perl'                  => '5.008001',
        'Attribute::Handlers'   => '0.77',
        'MRO::Compat'           => '0.11',
        'Storable'              => '2.04',
        'Test::Simple'          => '0.78',
        'Test::Builder'         => $tb_v,
        'Test::Builder::Tester' => '1.02',
        'Carp'                  => '0',
        'File::Find'            => '0',
        'File::Spec'            => '0',
        'constant'              => '0',
        'strict'                => '0',
        'warnings'              => '0',
    },
    build_requires => {
        'Test::Exception'       => '0.25',
        'IO::File'              => '1.09',
        'Test::More'            => '0.78',
        'Fcntl'                 => '0',
        'Test'                  => '0',
        'base'                  => '0',
        'overload'              => '0',
    },
    meta_merge => {
        resources => {
            repository => 'http://github.com/adrianh/test-class/',
        },
    },
    create_makefile_pl => 'traditional',
    create_readme      => 1,
);
$build->create_build_script;
