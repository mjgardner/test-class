use Module::Build;

my $build = Module::Build->new(
    module_name => 'Test::Block',
    license => 'perl',
    requires => {
        'perl'           => '5.6.1',
    },
    build_requires => {
        'Test::Builder'         => '0.17',
        'Test::Builder::Tester' => '0.09',
        'Test::More'            => '0.47',
        'Test::Exception'       => '0.15',
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
    sign => 1,
);
$build->create_build_script;
