#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 5;

BEGIN {
    use_ok( 'Game::Term' ) || print "Bail out!\n";
    use_ok( 'Game::Term::UI' ) || print "Bail out!\n";
    use_ok( 'Game::Term::Map' ) || print "Bail out!\n";
    use_ok( 'Game::Term::Hero' ) || print "Bail out!\n";
    use_ok( 'Game::Term::Config' ) || print "Bail out!\n";
}

diag( "Testing Game::Term $Game::Term::VERSION, Perl $], $^X" );
