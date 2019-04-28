use strict;
use warnings;
use Game::Term::Game;

use Game::Term::Scenario;

use Game::Term::Actor;
use Game::Term::Actor::Hero;

# # bare minimum scenario with map in DATA
# my $scenario = Game::Term::Scenario->new();
# $scenario->{name} ='Test Scenario 1';
# $scenario->get_map_from_DATA();
# $scenario->set_hero_position( $ARGV[0] // 'south11' );

# OR scenario with custom fake map
my $scenario = Game::Term::Scenario->new( 
				map=> Game::Term::Map->new(fake_map=>'one')->{data},
				name => 'Test Scenario 2',
				creatures => [
					Game::Term::Actor->new(	
											name=>'UNO',
											y=>26,
											x=>31,
											energy_gain=>2),

					#Game::Term::Actor->new(name=>'UNO',energy_gain=>2),
					
				]);
#use Data::Dump; dd $scenario;
$scenario->set_hero_position( $ARGV[0] // 'south38' );


my $conf = Game::Term::Configuration->new();
# OR
# my $conf = Game::Term::Configuration->new( from=>'./conf.txt' );
# changes to configuration...
# $conf->{interface}{masked_map} = 0;

my $hero = Game::Term::Actor::Hero->new( name => 'My New Hero' );

my $game=Game::Term::Game->new( 
								debug=>0, 
								configuration => $conf, 
								#map => $scenario->{map},
								scenario => $scenario,
								hero	=> $hero,
								#actors	=> [],
							);


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