use strict;
use warnings;
use Game::Term::Game;

use Game::Term::Scenario;

my $scenario = Game::Term::Scenario->new();
$scenario->{name} ='Test Scenario 1';
$scenario->get_map_from_DATA();

my $conf = Game::Term::Configuration->new( );
# changes to configuration...
$conf->{interface}{masked_map} = 0;

my $game=Game::Term::Game->new( debug=>0, configuration => $conf, map => $scenario->{map}); 
# use Data::Dump; local $game->{ui}->{map} = [qw(fake data)]; dd $game; exit;
# use Data::Dump; local $scenario->{map} = [qw(fake data)]; dd $scenario; exit;

$game->play()

__DATA__
WWWWWWWWWWWWWWWWWWWW
     tttt  T        
 ttt    tTT t       
    tt    tT        
wwwwwwwwww          
  ttt           mM  
    wW              
              ww    
             wWwW   
TTTTTTTTT           
S        X         S