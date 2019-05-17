use strict;
use warnings;

use Game::Term::Game;
use Game::Term::Scenario;
use Game::Term::Actor;
use Game::Term::Actor::Hero;
use Game::Term::Event;

# # bare minimum scenario with map in DATA
# my $scenario = Game::Term::Scenario->new();
# $scenario->{name} ='Test Scenario 1';
# $scenario->get_map_from_DATA();
# $scenario->set_hero_position( $ARGV[0] // 'south11' );

# OR scenario with custom fake map
my $scenario = Game::Term::Scenario->new( 
				map=> Game::Term::Map->new(fake_map=>'one')->{data},
				name => 'Test Scenario 2',
				actors => [
					Game::Term::Actor->new(	
											name=>'UNO',
											y=>26,
											x=>31,
											#y=>5,

											# x=>11,
											# energy_gain=>20),

											#x=>5,
											energy_gain=>4),

					Game::Term::Actor->new(name=>'DUE',y=>28, x=>41,energy_gain=>2),
					Game::Term::Actor->new(name=>'TRE',y=>28, x=>51,energy_gain=>2),
					#Game::Term::Actor->new(name=>'UNO',energy_gain=>2),
					
				],
				
				events => [
					Game::Term::Event->new( 
											type 	=> 'game turn', 
											check 	=> 3, # turn 3
											target 	=> 'hero', # special string for hero
											target_attr => 'energy_gain',
											target_mod 	=> 5,
											duration => 3,
											message	=> 'BUFF! energy gain +5 for 3 turns',
											
											
											),#
					Game::Term::Event->new( 
											type 	=> 'game turn', 
											check 	=> 5, # turn 5
											target 	=> 'DUE', # the name of the actor
											target_attr => 'energy_gain',
											target_mod 	=> 5,
											duration => 3,
											message	=> 'BUFF! energy gain +5 for 3 turns',
											
											
											),#
					Game::Term::Event->new( 
											type 	=> 'game turn', 
											check 	=> 10, 
											target 	=> 'hero', 
											target_attr => 'sight',
											target_mod 	=> 5,
											duration => 3,
											message	=> 'BUFF! sight radius +5 for 3 turns',
											
											
											),#
											
					Game::Term::Event->new( 
											type => 'actor at',
											target => 'hero',
											check => [29,38], # [y,x]
											first_time_only => 0,								
											message	=> 'creature at 29-38',
											),#
				],
);
# use Data::Dump; $scenario->{map}=[]; dd $scenario;
$scenario->set_hero_position( $ARGV[0] // 'south38' );


my $conf = Game::Term::Configuration->new();
# OR
# my $conf = Game::Term::Configuration->new( from=>'./conf.txt' );
# changes to configuration...
# $conf->{interface}{masked_map} = 0;

my $hero = Game::Term::Actor::Hero->new( name => 'My New Hero' );

my $game=Game::Term::Game->new( 
								debug=>1,  # NO bug
								configuration => $conf, 
								scenario => $scenario,
								hero	=> $hero,
								
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