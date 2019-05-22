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
my $scenario = Game::Term::Scenario->new(
	events	=> [
					Game::Term::Event->new( 
						type => 'door',
						target => 'hero',
						check => [6,19], 
						first_time_only => 0,								
						message	=> 'a hole in the floor, casting light..',
						destination => [
										'./demo/00-start.pl', 
										'middle', 15, 38
										],
					),
					Game::Term::Event->new( 
						type => 'door',
						target => 'hero',
						check => [18,0], 
						first_time_only => 0,								
						message	=> 'a hole in the floor, casting light..',
						destination => [
										'./demo/00-start.pl', 
										'middle', 18,17
										],
					),#

				],

);
$scenario->{name} ='A small cave under the river';
$scenario->get_map_from_DATA();
$scenario->set_hero_position( $ARGV[0] // 'south11' );


$scenario->set_hero_position( $ARGV[0] // 'east5' );


my $hero = Game::Term::Actor::Hero->new( 
											name => 'My New Hero',
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
											
);

my $game=Game::Term::Game->new( 
								debug=>2,  # NO bug
								# configuration => $conf, 
								scenario => $scenario,
								hero	=> $hero,
								
							);


$game->play()

__DATA__
#   #############www
###         #####www
### ### ###   wwwwww
### # # #### #######
#w  # # #### #######
#w### #   ##   ##   
#w### # ww ###     d
#www  # www####### #
##ww### ww     ##  #
  w       ####    ##
# w############# ###
## #  ########## ###
##    ########## ###
##### #    ##### ###
#####   ##     # ###
###########  #   ###
######ww ######  ###
    #www  ###### ###
d   wwwww   ###  ###
    wwwwww      ####