use strict;
use warnings;

use Game::Term::Game;
use Game::Term::Scenario;
use Game::Term::Actor;
use Game::Term::Actor::Hero;
use Game::Term::Event;
use Game::Term::Item;

# # bare minimum scenario with map in DATA
my $scenario = Game::Term::Scenario->new();
$scenario->{name} ='Test Scenario 1';
$scenario->get_map_from_DATA();
$scenario->set_hero_position( $ARGV[0] // 'south11' );


# use Data::Dump; $scenario->{map}=[]; dd $scenario;
$scenario->set_hero_position( $ARGV[0] // 'south38' );


my $conf = Game::Term::Configuration->new();


# my $hero = Game::Term::Actor::Hero->new( 
											# name => 'My New Hero',
											# bag => [
												# Game::Term::Item->new(
													# name => 'potion of sight',
													# duration => 3,
													# consumable => 1,
													# target_attr => 'sight',
													# target_mod	=> 10,
													# message => 'Glu.. Glu..',
													
												# ),
											# ],
# );

my $game=Game::Term::Game->new( 
								debug=>1,  # NO bug
								configuration => $conf, 
								scenario => $scenario,
								#hero	=> $hero,
								
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
tTtTtTtTt           
S                  S