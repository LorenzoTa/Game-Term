use strict;
use warnings;
use Game::Term::Game;

use Game::Term::Scenario;


my $scenario = Game::Term::Scenario->new( map=> Game::Term::Map->new(fake_map=>'one')->{data} );
$scenario->{name} ='Test Scenario 1';
#$scenario->get_map_from_DATA();

$scenario->set_hero_position( $ARGV[0] // 'south38' );


my $conf = Game::Term::Configuration->new( );
# changes to configuration...
$conf->{interface}{masked_map} = 0;

my $game=Game::Term::Game->new( 
								debug=>2, 
								configuration => $conf, 
								#map => $scenario->{map},
								scenario => $scenario,
							); 
# use Data::Dump; local $game->{ui}->{map} = [qw(fake data)]; dd $game; exit;
# use Data::Dump; local $scenario->{map} = [qw(fake data)]; dd $scenario; exit;
#use Data::Dump;   dd $scenario; exit;

$game->play()

__DATA__
WWWWWWwwwwwwwwWWWWWW
     tttt           
 ttt    tTT t       
    tt    tT        
wwwwwwwwww          
  ttt           mM  
    wW              
              ww    
             wWwW   
TTTTTTTTT           
S                  S