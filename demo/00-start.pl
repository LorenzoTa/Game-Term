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
				#map=> Game::Term::Map->new(fake_map=>'one')->{data},
				name => 'A river in the wood',
				actors => [
					Game::Term::Actor->new(name=>'UNO',y=>32, x=>33,energy_gain=>4),
					Game::Term::Actor->new(name=>'DUE',y=>28, x=>41,energy_gain=>2),
					Game::Term::Actor->new(name=>'TRE',y=>28, x=>51,energy_gain=>2),
										
				],
				
				events => [
					# Game::Term::Event->new( 
											# type 	=> 'game turn', 
											# check 	=> 3, # turn 3
											# target 	=> 'hero', # special string for hero
											# target_attr => 'energy_gain',
											# target_mod 	=> 5,
											# duration => 3,
											# message	=> 'BUFF! energy gain +5 for 3 turns',
											
											
											# ),#
					Game::Term::Event->new( 
											type 	=> 'game turn', 
											check 	=> 5, # turn 5
											target 	=> 'DUE', # the name of the actor
											target_attr => 'energy_gain',
											target_mod 	=> 5,
											duration => 50,
											message	=> 'BUFF! energy gain +5 for 3 turns',
											
											
											),#
					# Game::Term::Event->new( 
											# type 	=> 'game turn', 
											# check 	=> 10, 
											# target 	=> 'hero', 
											# target_attr => 'sight',
											# target_mod 	=> 5,
											# duration => 3,
											# message	=> 'BUFF! sight radius +5 for 3 turns',
											
											
											# ),#
											
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
											# ARGV passed to the program are used to set hero's position
											# two form are supported: a single argument sideN (like in east23 or north12) 
											destination => ['./demo/01-cave.pl', 'east6'],
											),#
					
					Game::Term::Event->new( 
											type => 'door',
											target => 'hero',
											check => [18,17], 
											first_time_only => 0,								
											message	=> 'a cave open in ground..',
											# ARGV passed to the program are used to set hero's position
											# a multiple argument with coordinates: middle 13 45 or middle 23 56
											destination => ['./demo/01-cave.pl', 'middle',18,0],
											),#
					
					Game::Term::Event->new( 
											type => 'map view',
											target => 'hero',
											check => [31,32], # [y,x]
											# check can be an AREA too:
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

$scenario->get_map_from_DATA();

$scenario->set_hero_position( @ARGV ? @ARGV : 'south38' );

# CONFIGURATION defualt (16 colors)
my $conf = Game::Term::Configuration->new();

# Linux and win10 users can use 256 colors
# my $conf = Game::Term::Configuration->new( map_colors=>256 );

# CONFIGURATION from file
# my $conf = Game::Term::Configuration->new( from=>'./conf.txt' );
# changes to configuration...
# $conf->{interface}{masked_map} = 0;


# HERO must be created in the first scenario
my $hero = Game::Term::Actor::Hero->new( 
											name => 'My New Hero',
											bag => [
												Game::Term::Item->new(
													name => 'potion of sight',
													duration => 5,
													consumable => 1,
													target_attr => 'sight',
													target_mod	=> 10,
													message => 'Glu.. Glu..',
													
												),
												Game::Term::Item->new(
													name => 'potion of sight',
													duration => 5,
													consumable => 1,
													target_attr => 'sight',
													target_mod	=> 10,
													message => 'Glu.. Glu..',
													
												),
												Game::Term::Item->new(
													name => 'potion of sight',
													duration => 5,
													consumable => 1,
													target_attr => 'sight',
													target_mod	=> 10,
													message => 'Glu.. Glu..',
													
												),
											],
);

# the GAME main object
my $game=Game::Term::Game->new( 
								debug			=> $ENV{PERL_GAMETERM_DEBUG}//0,
								configuration 	=> $conf, 
								scenario 		=> $scenario,
								hero			=> $hero,
								
							);

# start the game loop
$game->play()

__DATA__
tttt ttTTTTTTTTTTTTTTTTTTTTTTTTTTmmmMMWWwwMMttt ttmMMMMmmmmmmmmMtMMMMM hhhhhMMMM
ttttt ttttTTTTTTTTTTTTTTTTTTTTTTTmmmmmWWMwmttttttmMMMmtttthhmmmMMmmmmmttt  httmm
ttttttTTTTTttttttTTTTTttttttttttt  bbWWwwmmttttttmMM ht MttthhmMMmmm tt hhhhMMmm
 ttttTTtttttttttttttttttttttttttt WWbbwtwmmttttttmMhhh  MMMthhmMMmmthhhhh tMtmmt
 tttTTttt                   ttttWWWwwbbwtmmtttttt M hh   MMtttt tmm hhtth MMmmMt
   tttt     tttttttt           WWwwwwwbbtttttttt  MMMMmm      tttMmhh tth Mmm tt
   Tt     tttttttttt          WWwwhhhhh    tttt   MMMMMm         Mthhtt Mmmm mtt
   ttt  ttwwwwwtt     ttttttAAAAAhhhhh     tttt       Mmmm      MMt  t Mmmtmmm t
  tt   ttwwwwwwww   ttttttt AAAAAhhmMMM     ttt          m   MMmmhhh   Mm t t  t
  t   tttwwWWWWww  ttttttt   WWwhhhmMMMM    ttt        mmm   Mmhhhmh MMMm t   tt
     ttttwwBBWWww  tt tt     WWwwhhhMM                mmMMMMMhhhtmhh     tttt tt
     ttttwBBWWWww  t  t       Wwwwhh             ttt   MMhhhhhttttmtmm  tttttttt
     ttttBBwWWWww  t  hmmmh   WWwwww     tttttttttttt  MMhttttttttmmmm  tttttttt
     tttBBwwwwww   tt hhhmh    WWwwww   tttttttTTtttt                m   ttttt t
     ttttttwwwwtttttthhhhhh      WWww   ttttttttTTTTttttTttt       ttmmm   ttttt
      ttt tttttt tt t            WWwwwd   tttttttttTTtttTTTttt     tttTt      tt
             tt tt      WWWWWWaaWWwwww      tttttttttttttttTTtt    tttTttt      
          hhhh  t   WWWWWWwwwwaawwwwww      tt           tttTtt     ttTTTt     t
         mmhhhhttdWWWwwwwwwsss   wwwww                      ttttt     ttTTtttttt
      h mm ht  tssWWwwssssssss    sss                       ttttt      tTtttttTt
     hhmmhttttttswWwssssssss       ss      tttt                 tttt      tttTtt
     hhhhhttttttswWwsSSssSSs           ttttttt   ttttt       tttt           tTTT
         ttttt sswwwssSSSSSs           tttttt    ttttt        tTt       ttttttTT
        tttttsssswwWwsSSSSSSss        ttttttt    ttttt      tttTt      ttttttTTt
        tt   sssswWwwsssSSSSSs       tthhttt    tttt       ttTTTt      tttTTTTTt
       ttt ssssswWwwwssssSSsss   ttttthhhht    sssss       tTTttt      tttttttTt
           ssssswWwwwwsssssss    tthhhhhht     ssSSss      tTTt             ttTT
           sswwwwWWWwwwsssssss    hhhhhhtt     ssSSSss                      tttT
          sswwWWWWWWWwwwssssss      ttttt  yyt tsssssss                ttt  tttT
         sswwWWWWWWWWWWWwwwssss          yyyytttt  ttt           tt   tttt  ttTT
 t      sswwWWWWWWWWWWWWWWWWwws          TTTTTTTttt    ttt ttttttttttttttt  ttTt
ttt    ssswWWWWWWWWWWWWWWWWWWwww         TTTTTTTTTttt tt ttttTTTTtttttttttttTTTt
ttt  ssssswWWWWWWWWWWWWWWWWWWWWWw       TTTTTTTTTTTtt tTTTTTTTttTTTTTTtttttttttt