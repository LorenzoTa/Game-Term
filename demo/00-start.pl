use strict;
use warnings;
use lib './lib';
use Game::Term::Game;
use Game::Term::Scenario;
use Game::Term::Actor;
use Game::Term::Actor::Hero;
use Game::Term::Event;
use Game::Term::Item;

# # bare minimum scenario with map in DATA
# my $scenario = Game::Term::Scenario->new();
# $scenario->{name} ='Test Scenario 1';
# $scenario->get_map_from_DATA();
# $scenario->set_hero_position( $ARGV[0] // 'south11' );

# OR scenario with custom fake map
my $scenario = Game::Term::Scenario->new( 
				map=> Game::Term::Map->new(fake_map=>'one')->{data},
				name => 'A river in the wood',
				actors => [
					Game::Term::Actor->new(	
											name=>'UNO',
											y=>26,
											x=>31,
											energy_gain=>4),

					Game::Term::Actor->new(name=>'DUE',y=>28, x=>41,energy_gain=>2),
					Game::Term::Actor->new(name=>'TRE',y=>28, x=>51,energy_gain=>2),
										
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
											#check => [ [29,36],[29,37],[29,38],[29,39] ],
											first_time_only => 0,								
											message	=> 'hero at 29-38',
											),#
											
					Game::Term::Event->new( 
											type => 'door',
											target => 'hero',
											check => [15,38], 
											first_time_only => 0,								
											message	=> 'a cave open in ground..',
											destination => ['./demo/01-cave.pl', 'east6'],
											),#
					
					Game::Term::Event->new( 
											type => 'door',
											target => 'hero',
											check => [18,17], 
											first_time_only => 0,								
											message	=> 'a cave open in ground..',
											destination => ['./demo/01-cave.pl', 18,0],
											),#
					
					Game::Term::Event->new( 
											type => 'map view',
											target => 'hero',
											check => [31,32], # [y,x]
											#check => [ [29,36],[29,37],[29,38],[29,39] ],
											area => [
														[30,23],[30,24],[30,25],[30,26],[30,27],
														[31,23],[31,24],[31,25],[31,26],[31,27],
														[32,23],[32,24],[32,25],[32,26],[32,27],
													],
											# first_time_only => 1,	# always cleared							
											message	=> 'whatch the river!',
											),#
				],
);

$scenario->set_hero_position( @ARGV ? @ARGV : 'south38' );


my $conf = Game::Term::Configuration->new();
# OR
# my $conf = Game::Term::Configuration->new( from=>'./conf.txt' );
# changes to configuration...
# $conf->{interface}{masked_map} = 0;

my $hero = Game::Term::Actor::Hero->new( 
											name => 'My New Hero',
											bag => [
												Game::Term::Item->new(
													name => 'potion of sight',
													duration => 3,
													consumable => 1,
													target_attr => 'sight',
													target_mod	=> 10,
													message => 'Glu.. Glu..',
													
												),
											],
);

my $game=Game::Term::Game->new( 
								debug=>2,  # NO bug
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