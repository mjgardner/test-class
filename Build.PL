use Module::Build;

my $build = Module::Build->new(
    module_name => 'Test::Class',
    license     => 'perl',
    requires    => {
        'perl'                  => '5.6.1',
        'Attribute::Handlers'   => '0.77',
        'Class::ISA'            => '0.32',
        'Devel::Symdump'        => '2.03',
        'IO::File'              => '1.14',
        'Storable'              => '2.04',
        'Test::Simple'          => '0.62',
        'Test::Builder'         => '0.33',
        'Test::Builder::Tester' => '1.04',
        'Test::More'            => '0.44',
        'Test::Exception'       => '0.15',
    },
    create_makefile_pl => 'traditional',
    create_readme      => 1,
);
$build->create_build_script;
