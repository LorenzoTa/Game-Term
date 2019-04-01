use strict;
use warnings;
use Game::Term::Game;

my $conf = Game::Term::Configuration->new();
# changes to configuration...
# $conf->{interface}{masked_map} = 0;

my $game=Game::Term::Game->new( configuration => $conf); 

$game->play()

__DATA__
use Game::Term::UI;
use Game::Term::Configuration;
use Game::Term::Map;

use Data::Dump;

my $conf = Game::Term::Configuration->new();
# changes to configuration...
# $conf->{interface}{ext_tile} = '?';
# $conf->{interface}{masked_map} = 0;
# $conf->{interface}{fog_of_war} = 0;
# $conf->{interface}{map_area_w} = 80;

# UI called passing the configuration object
#my $ui = Game::Term::UI->new( configuration => $conf );
# my $ui = Game::Term::UI->new( configuration => $conf, debug => 2 );

# bare UI with defaults
 my $ui = Game::Term::UI->new(  );  # OK

# directly modify debugs
# $Game::Term::UI::debug = 1;
# $Game::Term::UI::debug = 2;
# $Game::Term::UI::noscroll_debug = 1;
$ui->run();