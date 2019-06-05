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
				labels => [
							[17,20,'Arunakosh'],
							[18,20,'river'],
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
											check => [	[23,21],
														[24,16],[24,21],
														[25,15],[25,16],[25,21],[25,22],[25,23],
														[26,14],[26,15],[26,16],[26,21],[26,22],[26,23],
														[27,13],[27,14],[27,15],[27,16],[27,21],[27,22],[27,23],[27,24],[27,25],[27,26],
														[28,12],[28,13],[28,14],[28,21],[28,22],[28,23],[28,24],[28,25],[28,26],[28,27],[28,28],
														[29,11],[29,12],[29,27],[29,28],[29,29],
														[30,10],[30,11],[30,28],[30,29],[30,30],
														[31,10],[31,29],[31,30],[31,31],[31,32],[31,9],
														[32,32],[32,8],[32,9]
											],
											area => [
														[17,20],
														[18,18],[18,19],[18,20],
														[19,18],[19,19],[19,20],
														[20,17],[20,18],[20,19],
														[21,17],[21,18],[21,19],
														[22,17],[22,18],[22,19],[22,20],
														[23,17],[23,18],[23,19],[23,20],
														[24,17],[24,18],[24,19],[24,20],
														[25,17],[25,18],[25,19],[25,20],
														[26,16],[26,17],[26,18],[26,19],[26,20],
														[27,13],[27,14],[27,15],[27,16],[27,17],[27,18],[27,19],[27,20],[27,21],
														[28,12],[28,13],[28,14],[28,15],[28,16],[28,17],[28,18],[28,19],[28,20],[28,21],[28,22],[28,23],
														[29,11],[29,12],[29,13],[29,14],[29,15],[29,16],[29,17],[29,18],[29,19],[29,20],[29,21],[29,22],[29,23],[29,24],[29,25],[29,26],
														[30,10],[30,11],[30,12],[30,13],[30,14],[30,15],[30,16],[30,17],[30,18],[30,19],[30,20],[30,21],[30,22],[30,23],[30,24],[30,25],[30,26],[30,27],
														[31,10],[31,11],[31,12],[31,13],[31,14],[31,15],[31,16],[31,17],[31,18],[31,19],[31,20],[31,21],[31,22],[31,23],[31,24],[31,25],[31,26],[31,27],[31,28],[31,29],
														[32,10],[32,11],[32,12],[32,13],[32,14],[32,15],[32,16],[32,17],[32,18],[32,19],[32,20],[32,21],[32,22],[32,23],[32,24],[32,25],[32,26],[32,27],[32,28],[32,29],[32,30],
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
ttttt ttttTTTTTTTTTTTTTTTTTTTTTTTmmmmmWWMwmttttttmMMMmtttthhmmmMMmmmmmttthhhttmm
ttttttTTTTTttttttTTTTTttttttttttt  bbWWwwmmttttttmMM ht MttthhmMM     t hh    mm
 ttttTTtttttttttttttttttttttttttt WWbbwtwmmttttttmMhhh  MMMthhmMM mth hhh     mt
 tttTTttt                   ttttWWWwwbbwtmmtttttt M hh   MMtttt   m h  th MMmmMt
   tttt     tttttttt           WWwwwwwbbtttttttt  MMMMmm      tttMmhh tth Mmm tt
   Tt     tttttttttt          WWwwhhhhh    tttt   MMMMMm         Mthhtt Mmmm mtt
   ttt  ttwwwwwtt     ttttttAAAAAhhhhh     tttt       Mmmm      MMt  t Mmmtmmm t
  tt   ttwwwwwwww   ttttttt AAAAAhhmMMM     ttt              MMmmhhh   M  t t  t
  t   tttwwWWWWww  ttttttt   WWwhhhmMMMM    ttt         mm   Mmhhhmh MM   t   tt
     ttttwwBBWWww  tt tt     WWwwhhhMM                 mMMMMMhhhtmhh     tttt tt
     ttttwBBWWWww  t  t       Wwwwhh             ttt   MMhhhhhttttmtmm  tttttttt
     ttttBBwWWWww  t  hmmmh   WWwwww     tttttttttttt  MMhttttt ttmmmm  tttttttt
     tttBBwwwwww   tt hhhmh    WWwwww   tttttttTTtttt                m   ttttt t
     ttttttwwwwtttttthhhhhh      WWww   ttttttttTTTTttttTttt       ttmmm   ttttt
      ttt tt  tt tt t            WWwwwd   tttttttttTTtttTTTttt     tttTt      tt
             tt tt      WWWWWWaaWWwwww      tttttttttttttttTTtt    tttTttt      
          hhhh  t   WWWWWWwwwwaawwwwww      tt           tttTtt     ttTTTt     t
         mmhhhhttdWWWwwwwwwsss   wwwww                      ttttt     ttTTtttttt
      h mm ht  t sWWwwssssssss    sss                       ttttt      tTtttttTt
     hhmmhtttttt wWWssssssss       ss      tttt                 tttt      tttTtt
     hhhhhtttt   wWWsSSssSSs           ttttttt   ttttt       tttt           tTTT
         tttt    wwwssSSSSSs           tttttt    ttttt        tTt       ttttttTT
        ttttt   swwWwsSSSSSSss        ttttttt    ttttt      tttTt      ttttttTTt
        tt    ssswWwwsssSSSSSs       tthhttt    tttt       ttTTTt      tttTTTTTt
       ttt ssssswWWwwssssSSsss   ttttthhhht    sssss       tTTttt      tttttttTt
           ssssswWWwwwsssssss    tthhhhhht     ssSSss      tTTt             ttTT
           sswwwWWWWwwwsssssss    hhhhhhtt     ssSSSss                      tttT
          sswwWWWWWWWwwwssssss      ttttt  yyt tsssssss                ttt  tttT
         sswwWWWWWWWWWWWwwwssss          yyyytttt  ttt           tt   tttt  ttTT
 t      sswwWWWWWWWWWWWWWWWWwws          TTTTTTTttt    ttt ttttttttttttttt  ttTt
ttt    ssswWWWWWWWWWWWWWWWWWWwww         TTTTTTTTTttt tt ttttTTTTtttttttttttTTTt
ttt  ssssswWWWWWWWWWWWWWWWWWWWWWw       TTTTTTTTTTTtt tTTTTTTTttTTTTTTtttttttttt