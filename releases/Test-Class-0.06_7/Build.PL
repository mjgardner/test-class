use Module::Build;

my $build = Module::Build->new(
    module_name => 'Test::Class',
    license => 'perl',
    requires => {
        'perl'           => '5.6.1',
    },
    build_requires => {
    	Attribute::Handlers		=> 0.77,
    	Class::ISA				=> 0.32,
    	IO::File				=> 1.08,
    	Storable				=> 2.04,
    	Test::Builder			=> 0.16,
    	Test::Builder::Tester	=> 0.09,
    	Test::Differences		=> 0.43,
    	Test::Exception			=> 0.10,
    	Test::More				=> 0.44,
    	Devel::Symdump			=> 2.03,
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
    sign => 1,
);
$build->create_build_script;
