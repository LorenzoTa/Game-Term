use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Game::Term',
    AUTHOR           => q{LorenzoTa <lorenzo@cpan.org>},
    VERSION_FROM     => 'lib/Game/Term.pm',
    ABSTRACT_FROM    => 'lib/Game/Term.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.014',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Term::ANSIColor'              => '4.00', # https://metacpan.org/changes/distribution/Term-ANSIColor#L70
		'YAML::XS'	=> '0',
		# 
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Game::Term-*' },
);
