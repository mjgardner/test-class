use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => 'Test::Exception',
    'VERSION_FROM'  => 'Exception.pm', 
    'PREREQ_PM'     => {
        Test::Builder 			=> '0.13',
        Test::Builder::Tester	=> '0.08',
        Test::More				=> '0.44',
        Test::Harness			=> '2.03',
        Sub::Uplevel			=> '0.06',
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Exception.pm',
       AUTHOR     => 'Adrian Howard <adrianh@quietstars.com>') : ()),
);
