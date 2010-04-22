use Module::Build;

my $build = Module::Build->new(
    module_name => 'Test::Class',
    license     => 'perl',
    requires    => {
        'perl'                  => '5.006001',
        'Attribute::Handlers'   => '0.77',
        'MRO::Compat'           => '0.11',
        'Storable'              => '2.04',
        'Test::Simple'          => '0.78',
        'Test::Builder'         => '0.78',
        'Test::Builder::Tester' => '1.02',
        'Test::More'            => '0.78',
    },
    build_requires => {
        'Test::Exception'       => '0.25',
        'IO::File'              => '1.09',
    },
    create_makefile_pl => 'traditional',
    create_readme      => 1,
);
$build->create_build_script;
