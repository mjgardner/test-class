use Module::Build;

my $build = Module::Build->new(
    module_name => 'Test::Class',
    license     => 'perl',
    requires    => {
        'perl'                  => '5.006001',
        'Attribute::Handlers'   => '0.77',
        'Class::ISA'            => '0.32',
        'Devel::Symdump'        => '2.03',
        'IO::File'              => '1.09',
        'Storable'              => '2.04',
        'Test::Simple'          => '0.78',
        'Test::Builder'         => '0.78',
        'Test::Builder::Tester' => '1.02',
        'Test::More'            => '0.78',
        'Test::Exception'       => '0.25',
    },
    create_makefile_pl => 'traditional',
    create_readme      => 1,
);
$build->create_build_script;
