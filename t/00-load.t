#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 8;

BEGIN {
    use_ok( 'Game::Term' ) || print "Bail out!\n";
    use_ok( 'Game::Term::UI' ) || print "Bail out!\n";
    use_ok( 'Game::Term::Map' ) || print "Bail out!\n";
	use_ok( 'Game::Term::Scenario' ) || print "Bail out!\n";
	use_ok( 'Game::Term::Event' ) || print "Bail out!\n";
	use_ok( 'Game::Term::Actor' ) || print "Bail out!\n";
    use_ok( 'Game::Term::Actor::Hero' ) || print "Bail out!\n";
    use_ok( 'Game::Term::Configuration' ) || print "Bail out!\n";
}

diag( "Testing Game::Term $Game::Term::VERSION, Perl $], $^X" );
