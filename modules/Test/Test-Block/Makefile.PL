use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'      => 'Test::Block',
    'VERSION_FROM'  => 'lib/Test/Block.pm', # finds $VERSION
    'PREREQ_PM'     => {
        'Test::Builder'         => '0.17',
        'Test::Builder::Tester' => '0.09',
        'Test::More'            => '0.47',
        'Test::Exception'       => '0.15',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Test/Block.pm', # retrieve abstract from module
       AUTHOR     => 'Adrian Howard <adrianh@quietstars.com>') : ()),
);
