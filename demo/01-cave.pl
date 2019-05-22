use strict;
use warnings;
use lib './lib';
use Game::Term::Game;
use Game::Term::Scenario;
use Game::Term::Actor;
use Game::Term::Actor::Hero;
use Game::Term::Event;
use Game::Term::Item;


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

# ARGV passed to the program are used to set hero's position
# two form are supported: a single argument sideN (like in east23 or north12) and
# a multiple argument with coordinates: middle 13 45 or middle 23 56
$scenario->set_hero_position( @ARGV );


# an HERO must be passed but will be filled with data
# hold in the GameState.sto file

my $hero = Game::Term::Actor::Hero->new( );

my $game=Game::Term::Game->new( 
								debug		=> 0, 
								scenario 	=> $scenario,
								hero		=> $hero,
								
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
                ####