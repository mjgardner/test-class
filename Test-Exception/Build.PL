use Module::Build;

my $build = Module::Build->new(
    module_name => 'Test::Block',
    license => 'perl',
    requires => {
        'perl'           => '5.6.1',
    },
    build_requires => {
        'Test::Builder'         => '0.13',
        'Test::Builder::Tester' => '1.01',
        'Test::More'            => '0.44',
        'Test::Harness'         => '2.03',
        'Sub::Uplevel'          => '0.06',
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
    sign => 1,
);
$build->create_build_script;
