package Game::Term::Game;

use 5.014;
use strict;
use warnings;

use File::Spec;
use YAML::XS qw(Dump DumpFile LoadFile);
use Storable qw(store retrieve);
use Time::HiRes qw ( sleep );
use Carp;
use Data::Dump;

use Game::Term::Configuration;
use Game::Term::UI;

use Game::Term::Actor;
use Game::Term::Actor::Hero;

use Game::Term::Event;

our $VERSION = '0.01';

my $debug = 0;

sub new{
	my $class = shift;
	my %param = @_;
	$debug = $param{debug};
	# GET hero..
	# if $param{hero} or ..	
	$param{configuration} //= Game::Term::Configuration->new();
	
	$param{scenario} //= Game::Term::Scenario->new( );

	$param{ui} //= Game::Term::UI->new( 
										configuration => $param{configuration}, 
										title => $param{scenario}->{name},
										map => $param{scenario}->{map},
										debug => $param{debug},
										
										);
	$param{scenario}->{map} = undef;
	
	# check saved scenario data (actors and map)!!
	my @actors = @{$param{scenario}->{actors}};
	#use Data::Dump; dd $param{scenario};
	$param{scenario}->{actors} = undef;
	
	my @events = @{$param{scenario}->{events}};
	$param{scenario}->{events} = undef;
	
	my $game = bless {
				is_running => 1,
				
				configuration => $param{configuration} ,
				
				# scenario => $param{scenario}, ### ??????
				current_scenario => $param{scenario}->{name},
				
				ui	=> $param{ui},
				
				hero => $param{hero},
				actors	=> [ @actors ],
				
				events => [ @events ],
				
				timeline => [],
				
				messages	=> [],
				
				turn => 0,
				
				
	}, $class;
	# push time events in the timeline (removing from events)
#$game->init_timeline();
	# load and overwrite info about hero and current scenario(map,actors,..)from gamestate.sto
#$game->get_game_state();
	
	# INJECT into UI parameters (once defined in Configuration.pm)
	$game->{ui}->{ hero_icon } 		=	$game->{hero}->{icon};
	$game->{ui}->{ hero_color } 	=	$game->{hero}->{color};
	#$game->{ui}->{ hero_sight } 	= 	$game->{hero}->{sight};
	#$game->{ui}->{ hero_slowness } 	=	$game->{hero}->{slowness};
	$game->{ui}->{hero_terrain}		=   'plain';
	
	
	# beautify the map and others..
	$game->{ui}->init();
	# apply MASK now!
	$game->get_game_state();
	


	# INJECT into UI HERO now!
	$game->{ui}->{ hero } = $game->{ hero };

	$game->{hero}{on_tile}			= 	'plain';
	
	if ($debug > 1){
		print "HERO addresses: game: $game->{ hero } UI: $game->{ui}->{ hero }\n";
		local $game->{ui}->{map} = ["FAKE","DATA"];
		print "DEBUG: UI after injections by Game object constructor:\n";
		dd $game->{ui};
	}
	
	return $game;
}

sub init_timeline{
	my $game = shift;
	foreach my $ev( @{$game->{events}} ){
		next unless $ev->{type} eq 'game turn';
		my $given_turn = $ev->{check};
		delete $ev->{check};
		push @{$game->{timeline}[ $given_turn ]}, $ev;
		undef $ev;	
	}
	dd "TIMELINE(init)",$game->{timeline} if $debug > 1;
}

sub get_game_state{
	my $game = shift;
	my $state_file = File::Spec->catfile( 
						$game->{configuration}{interface}{game_dir},
						'GameState.sto' 
	);
	print "DEBUG: assuming game state file at $state_file\n" if $debug;
	# global state of the game with hero and seen scenario informations:
	# %game_state = ( hero=> x, scn1=>(map,creature..), scn2=> ...
	my $game_state;
	# check for its content
	if ( -e -r -s -f $state_file ){
		$game_state = retrieve( $state_file ) 
			or die "Unable to retrieve game state from $state_file";
		# use Data::Dump; dd $game_state if $debug;
		# LOAD hero
		$game->{hero} = $$game_state->{hero};
		# reset hero's unneeded fields
		$game->{hero}{y} = undef;
		$game->{hero}{x} = undef;
		$game->{hero}{on_tile} = undef;
		$game->{hero}{energy} = 0;
		print "DEBUG: loaded HERO from $state_file\n" if $debug;
		dd "hero (after gamestate import)",$game->{hero} if $debug > 1;
		
		# LOAD TIMELINE
		foreach my $turn(0..$#{ $$game_state->{timeline} }){
			next unless defined $$game_state->{timeline}->[ $turn ];
			print "DEBUG: importing events in timeline from gamestate for turn $turn\n" if $debug;
			push @{$game->{timeline}[ $turn ]},
				@{$$game_state->{timeline}->[ $turn ]};
		}
		dd "TIMELINE(gamestate)",$game->{timeline} if $debug > 1;
		
		# eventually LOAD data of the current scenario
		if(	$$game_state->{ $game->{current_scenario} } ){
			print "DEBUG: loaded data of '$game->{current_scenario}' from $state_file\n" 
				if $debug;
			# LOAD actors
			$game->{actors} = $$game_state->{ $game->{current_scenario} }{actors};
			dd "loaded ACTORS:", $game->{actors} if $debug > 1;
			# LOAD events
			$game->{events} = $$game_state->{ $game->{current_scenario} }{events};
			dd "loaded EVENTS:", $game->{events} if $debug > 1;
			# LOAD map mask
			print "DEBUG: applying mask from GameState to the map\n" if $debug;
			print "DEBUG: mask retrieved:\n" if $debug > 1;
			foreach my $row ( 0..$#{$game->{ui}{map}} ){
				foreach my $col ( 0..$#{$game->{ui}{map}->[$row]} ){
					#$mask->[$row][$col] = $game->{ui}{map}->[$row][$col][2];
					next unless ref $game->{ui}{map}->[$row][$col] eq 'ARRAY';
					$game->{ui}{map}->[$row][$col]->[2]
					=
					$$game_state->{ $game->{current_scenario} }{map_mask}->[$row][$col];
										
					print $$game_state->{ $game->{current_scenario} }{map_mask}->[$row][$col]
						if $debug > 1;
				}
				print "\n" if $debug > 1;
			}
		}
		else{
			print "DEBUG: no data of '$game->{current_scenario}' in $state_file\n" if $debug;
			$game->init_timeline();
		}		
	}
	# GameState.sto does not exists
	else {
		print "DEBUG: $state_file not found (a new one will be created)\n" if $debug;
		# create with just hero inside
		$game_state = { hero => $game->{hero} };
		die "Unable to store into $state_file!" unless store ( \$game_state, $state_file );
		$game->init_timeline();
	}	
}

sub save_game_state{
	my $game = shift;
	my $state_file = File::Spec->catfile( 
						$game->{configuration}{interface}{game_dir},
						'GameState.sto' 
	);
	my $game_state;
	# check for its content
	if ( -e -r -s -f $state_file ){
		$game_state = retrieve( $state_file ) 
			or die "Unable to retrieve previous game state from $state_file";
		print "DEBUG: succesfully retrieved previous game state from $state_file\n" if $debug;
	}
	# GameState.sto does not exists
	else {
		print "DEBUG: $state_file not found: a new one will be created\n" if $debug;
		$game_state = {};
	}
	# POPULATE GameState.sto with the structure:
	
	# 1-HERO
	$$game_state->{ hero } = $game->{hero};
	
	# 2-TIMELINE 
	undef $$game_state->{ timeline };
	foreach my $turn ( $game->{turn}..$#{$game->{timeline}} ){
		next unless defined ${$game->{timeline}}[$turn];
		foreach my $ev( @{$game->{timeline}->[$turn]} ){
			if( $ev->{target} eq 'hero' ){
				push @{ $$game_state->{ timeline }[$turn - $game->{turn}] }, $ev;
			}
			else{
				$game->run_event($ev);
			}		
		}		
	}
	
	# 3-MASK of unmasked tiles of current scenario
	my $mask;
	foreach my $row ( 0..$#{$game->{ui}{map}} ){
		foreach my $col ( 0..$#{$game->{ui}{map}->[$row]} ){
			$mask->[$row][$col] = $game->{ui}{map}->[$row][$col][2];
		}
	}
	
	my @ev_to_save = grep{ defined } @{$game->{events}};
	$$game_state->{ $game->{current_scenario} } = {
						map_mask 	=> $mask,
						actors 		=> $game->{actors},
						events		=> [ @ev_to_save ],
	};
	
	die "Unable to store into $state_file!" unless store ( $game_state, $state_file );
	
	DumpFile( $state_file.'.yaml', $game_state ) if $debug;
	
}

sub play{
	my $game = shift;
	#INIT
	$game->{hero}->{y} = $game->{ui}->{hero_y};
	$game->{hero}->{x} = $game->{ui}->{hero_x};
	# ?? opposite: hero->on_tile = map
	# $game->{ui}->{map}[$game->{hero}->{y}][$game->{hero}->{x}] = [ " \e[0m",' ',0];
#$game->get_game_state();

	$game->{ui}->draw_map();
	$game->{ui}->draw_menu( 
							$game->{turn},
							$game->{hero},
							[ 
								"walk with WASD or : to enter command mode",
								#@{$game->{messages}->[ $game->{turn}]} 
							]
	);	

	while($game->{is_running}){
		# COMMAND
		if ($game->{ui}->{mode} and $game->{ui}->{mode} eq 'command' ){
			my @usr_cmd = $game->{ui}->get_user_command();
			next unless @usr_cmd;
			print "in Game.pm 'command' received: [@usr_cmd]\n" if $debug;
			$game->execute(@usr_cmd);
			next;
		}
		# MAP
		else{
			# FOREACH HERO,ACTORS
			foreach my $actor ( $game->{hero}, @{$game->{actors}} ){
				# undef actors were eliminated
				next unless defined $actor;
				# ACTOR CAN MOVE
				if ( $actor->{energy} >= 10 and $actor->isa('Game::Term::Actor::Hero') ){
					print join ' ',__PACKAGE__,'play'," DEBUG '$actor->{name}' --> can move\n"
						 if $debug;
					
					# PLAYER: GET USER COMMAND	
					my @usr_cmd = $game->{ui}->get_user_command();
					next unless @usr_cmd; # ??? last ???
					print "in Game.pm 'map' received: [@usr_cmd]\n" if $debug;
					
					if ($usr_cmd[0] eq ':'){
						$game->{ui}->{mode} = 'command';
						last;
					}
					# movement OK
					if ( $game->execute(@usr_cmd) ){
						# TIME
						$game->{turn}++;
						# EVENTS
						$game->check_events();
						# RENDER
						sleep(	
							$game->{hero}->{slowness} + 
							# the slowness #4 of the terrain original letter #1 where
							# the hero currently is on the map
							$game->{configuration}->{terrains}->{$game->{ui}->{map}->[ $game->{hero}->{y} ][ $game->{hero}->{x} ]->[1]}->[4]
						);
						# sigth modifications
						local $game->{hero}{sight} = $game->{hero}{sight} + 2 
							if $game->{ui}->{hero_terrain} eq 'hill';
						local $game->{hero}{sight}  = $game->{hero}{sight} + 4 
							if $game->{ui}->{hero_terrain} eq 'mountain';
						local $game->{hero}{sight} = $game->{hero}{sight} - 2 
							if $game->{ui}->{hero_terrain} eq 'wood';
												
						# draw screen (passing actors)
						$game->{ui}->draw_map(  @{$game->{actors}}  );
						$game->{ui}->draw_menu( 
							$game->{turn},
							$game->{hero},
							${$game->{messages}}[ $game->{turn}],
						);	
						$actor->{energy} -= 10;
					}
					# NO movement 
					else{
							print "DEBUG: no hero move\n" if $debug; 
							redo;
					}
				}	
				# NPC: AUTOMOVE
				elsif( $actor->{energy} >= 10 ){
						print join ' ',__PACKAGE__,'play'," DEBUG '$actor->{name}' --> can move\n" if $debug;
						# MOVE receives:
						my $newpos = $actor->move(
							# 1) hero position
							[$game->{hero}{y} , $game->{hero}{x}],
							# 2) and only valid tiles
							[
								grep {
										$$_[0] >= 0 and 
										$$_[0] <= $#{$game->{ui}->{map}} and
										$$_[1] >= 0 and
										$$_[1] <= $#{$game->{ui}->{map}[0]} and
										$game->is_walkable($game->{ui}->{map}->[ $$_[0] ]
													 [ $$_[1] ]) 
										
									} 
									[ $actor->{y} - 1, $actor->{x} ],
									[ $actor->{y} + 1, $actor->{x} ],
									[ $actor->{y} , $actor->{x} - 1],
									[ $actor->{y} ,$actor->{x} + 1]
							]
						) if $actor->can('move');
						
						$actor->{y} = $$newpos[0];
						$actor->{x} = $$newpos[1];
						# DRAW MAP only if actor is in sight range
						my %visible = $game->{ui}->illuminate();
						if ( exists $visible{ $actor->{y}.'_'.$actor->{x} } ){
							print "$actor->{name} in SIGHT!!\n" if $debug;
							$game->{ui}->draw_map(  @{$game->{actors}}  );
							$game->{ui}->draw_menu( 
								$game->{turn},
								$game->{hero},
								${$game->{messages}}[ $game->{turn}],
							);
						}
						$actor->{energy} -= 10;
						print "$actor->{name} at y: $actor->{y} / 0-$#{$game->{ui}->{map}} x: $actor->{x} / 0-$#{$game->{ui}->{map}[0]}\n" if $debug;
									
				}
				# CANNOT MOVE
				else{
					$actor->{energy} += $actor->{energy_gain};
					print __PACKAGE__," DEBUG '$actor->{name}' ends with energy $actor->{energy}\n" if $debug;
				}
				# ENCOUNTER
				if ( 
						!$actor->isa('Game::Term::Actor::Hero') and 
						$actor->{y} == $game->{hero}{y} and 
						$actor->{x} == $game->{hero}{x}  
				){
					print "KABOOOOM\n";
					undef $actor;
				}
			}
		}
	
	}
}

sub message{
	my $game = shift;
	my $msg	= shift;
	push @{ $game->{messages}[ $game->{turn} ] }, $msg;
	print "DEBUG: message $msg\n" if $debug;
	$game->{ui}->draw_map();
	$game->{ui}->draw_menu( #$game->{messages}[ $game->{turn} ] 
							$game->{turn},
							$game->{hero},
							${$game->{messages}}[ $game->{turn}],
						
	);
}

sub check_events{
	my $game = shift;
	print "DEBUG: checking events at turn $game->{turn}..\n" if $debug;
	# regular EVENTS + timeline EVENTS
	foreach my $ev( @{$game->{events}},@{$game->{timeline}[ $game->{turn} ]} ){
		next unless $ev;
		print "DEBUG: analyzing event of type: $ev->{type}..\n" if $debug;
		# target: HERO
		my $target;
		if( $ev->{target} eq 'hero' ){
			$target = \$game->{hero};
		}
		# target: other ACTOR
		elsif ( my @byname = grep{defined $_ and $_->{name} =~ /$ev->{target}/ }@{$game->{actors}}  ){
			$target = \$byname[0];		
		}
		# target: UNDEF
		else{ 
			print "DEBUG: event with undef target will be removed\n" if $debug;
			undef $ev;
			next;		
		}		
		# these events need to be CHECKED
		if ( 
				( 	
					$ev->{type} eq 'actor at' 	or
					$ev->{type} eq 'map view' 	or
					$ev->{type} eq 'door'		
				)								and  
				_is_inside( [$$target->{y}, $$target->{x}],  $ev->{check} )
		){
			$game->run_event( $ev, $target );
		}
		# game turn events RUN always (check is ignored)
		elsif( $ev->{type} eq 'game turn'){
			$game->run_event( $ev, $target );
		}
		else{ 
			print "DEBUG: skipping unmanaged event type: [$ev->{type}]\n";
			next;		
		}
	}
	# CLEAN timeline
	$game->{timeline}[ $game->{turn} ] = undef;
}

sub run_event{
	my $game = shift;
	my $ev = shift;
	my $target = shift;
	# events not passing via check_events are invoked without target
	unless ($target){
		# target: HERO 
		if( $ev->{target} eq 'hero' ){
			$target = \$game->{hero};
		}
		# target: other ACTOR
		elsif ( 
					my @byname = grep{defined $_ and 
					$_->{name} =~ /$ev->{target}/ }@{$game->{actors}}  
				){
			$target = \$byname[0];		
		}
		# target: UNDEF
		else{ 
			print "DEBUG: undef target event will be removed\n" if $debug;
			undef $ev;
			next;		
		}	
	}
	# event MESSAGE
	$game->message( $ev->{message} ) if ref $$target eq 'Game::Term::Actor::Hero';
	
	# GAME TURN type
	if ($ev->{type} eq 'game turn'){
		# ENERGY GAIN
		if ( $ev->{target_attr} and $ev->{target_attr} eq 'energy_gain' ){			
			$$target->{energy_gain} += $ev->{target_mod};						
		}
		# SIGHT (only for the hero)
		elsif( $ev->{target_attr} and $ev->{target_attr} eq 'sight' ){
			next unless ref $$target eq 'Game::Term::Actor::Hero';
			$$target->{sight} += $ev->{target_mod};
			# but sight is implemented in UI..
			$game->{ui}{hero_sight} += $ev->{target_mod};
		}
		else{die "Unknown target_attr!"}
		# DURATION ( a negative effect after some turn )
		if( $ev->{duration} ){
			push @{$game->{timeline}[ $game->{turn} + $ev->{duration} + 1]}, 
				Game::Term::Event->new( 
						type 	=> 'game turn', 
						check 	=> $game->{turn} + $ev->{duration} + 1, 
						message	=> "END of + $ev->{target_mod} $ev->{target_attr} buff",
						#target 	=> $ev->{target} eq 'hero' ? 'hero' : $ev->{target},
						target 	=> $ev->{target} ,
						target_attr => $ev->{target_attr},
						target_mod 	=> - $ev->{target_mod},										
				);
		}
		else { undef $ev }
	}
	# ACTOR at 
	elsif ( $ev->{type} eq 'actor at' ){
		print "DEBUG: nothing to do...\n"
	}	
	# MAP VIEW time
	elsif ( $ev->{type} eq 'map view' ){
		foreach my $tile( @{ $ev->{area} } ){
				$game->{ui}{map}[$tile->[0]][$tile->[1]][2] = 1;
			}
	}	
	# DOOR (ACTOR AT EVENT) type
	elsif ( $ev->{type} eq 'door' ){
		
		my $answer = $game->{ui}{reader}->readline('Enter?: ');
		chomp $answer;
		if( $answer =~ /^y/i ){
			$game->save_game_state();
			print "DEBUG: SYSTEM: ",(join ' ',$^X,'-I ./lib', @{ $ev->{destination} } ),"\n";
			undef $game;
			system( $^X,'-I .\lib', @{ $ev->{destination} } );
			exit;
		}
		else{ next }
		
	}
	else{ print  "DEBUG: nothing to do for event type: $ev->{type}\n" }

}

sub check_eventsORIGINAL{
	my $game = shift;
	print "DEBUG: checking events at turn $game->{turn}..\n" if $debug;
	
	# PROCESS regular events(all) AND events in the timeline for the current turn
	foreach my $ev( @{$game->{events}}, @{$game->{timeline}[ $game->{turn} ]} ){
		next unless $ev;
		print "DEBUG: analyzing event of type: $ev->{type}..\n" if $debug;
		
		# SELECT target:
		# HERO
		my $target;
		if( $ev->{target} eq 'hero' ){
			$target = \$game->{hero};
		}
		# other ACTOR
		elsif ( my @byname = grep{defined $_ and $_->{name} =~ /$ev->{target}/ }@{$game->{actors}}  ){
			$target = \$byname[0];		
		}
		# UNDEF
		else{ 
			print "DEBUG: undef target event will be removed\n" if $debug;
			undef $ev;
			next;		
		} 
# NEED a run_event method!!		
		# GAME TURN EVENT
		if ( $target and $ev->{type} eq 'game turn' ){
############next unless $ev->{check} == $game->{turn};
			
			#use Data::Dump; dd "BEFORE",$$target if $target;
			#print "EVENT MESSAGE: $ev->{message}\n" if $game->{is_running};
			$game->message( $ev->{message} ) if ref $$target eq 'Game::Term::Actor::Hero';
			# ENERGY GAIN
			if ( $ev->{target_attr} eq 'energy_gain' ){			
				$$target->{energy_gain} += $ev->{target_mod};						
			}
			# SIGHT (only for the hero)
			elsif( $ev->{target_attr} eq 'sight' ){
				next unless ref $$target eq 'Game::Term::Actor::Hero';
				$$target->{sight} += $ev->{target_mod};
				# but sight is implemented in UI..
				$game->{ui}{hero_sight} += $ev->{target_mod};
			}
			else{die "Unknown target_attr!"}
			
			# dd "AFTER",$$target;
			
			# DURATION ( a negative effect after some turn )
			if( $ev->{duration} ){
				push @{$game->{timeline}[ $game->{turn} + $ev->{duration} + 1]}, 
					Game::Term::Event->new( 
							type 	=> 'game turn', 
							check 	=> $game->{turn} + $ev->{duration} + 1, 
							message	=> "END of + $ev->{target_mod} $ev->{target_attr} buff",
							#target 	=> $ev->{target} eq 'hero' ? 'hero' : $ev->{target},
							target 	=> $ev->{target} ,
							target_attr => $ev->{target_attr},
							target_mod 	=> - $ev->{target_mod},										
					);
			}	
			
			#dd $game->{timeline} if $debug;			
			next;			
		}
		# ACTOR AT EVENT
		elsif ( $target and $ev->{type} eq 'actor at' ){
			
			next unless _is_inside( [$$target->{y}, $$target->{x}],  $ev->{check} );
			
			#print "EVENT MESSAGE: $ev->{message}\n" if $game->{is_running};
			$game->message( $ev->{message} ) if ref $$target eq 'Game::Term::Actor::Hero';
			undef $ev if  $ev->{first_time_only};
			
			next;
			
		}
		# MAP VIEW (ACTOR AT EVENT)
		elsif ( $target and $ev->{type} eq 'map view' ){
			
			next unless _is_inside( [$$target->{y}, $$target->{x}],  $ev->{check} );
			
			# print "EVENT MESSAGE: $ev->{message}\n" if $game->{is_running};
			
			foreach my $tile( @{ $ev->{area} } ){
				$game->{ui}{map}[$tile->[0]][$tile->[1]][2] = 1;
			}
			# $game->{ui}->draw_map();
			$game->message( $ev->{message} );
			undef $ev; # always for this kind of events
			
			next;
			
		}
		# DOOR (ACTOR AT EVENT)
		elsif ( $target and $ev->{type} eq 'door' ){
			
			next unless _is_inside( [$$target->{y}, $$target->{x}],  $ev->{check} );
			$game->message( $ev->{message} );
			my $answer = $game->{ui}{reader}->readline('Enter?: ');
			chomp $answer;
			if( $answer =~ /^y/i ){
					$game->save_game_state();
					print "DEBUG: SYSTEM: ",(join ' ',$^X,'-I ./lib', @{ $ev->{destination} } ),"\n";
					
					undef $game;
					#$game->DESTROY();
					
					system( $^X,'-I .\lib', @{ $ev->{destination} } );
					exit;
			}
			else{ next }
			
		}
		else{ die "Unknown event type in Game.pm" }
		
	}
	
	# CLEAN timeline
	$game->{timeline}[ $game->{turn} ] = undef;

}

sub _is_inside{
	my $it   = shift;
	my $area = shift;
	# an array of coordinates was passed
	if( ref $area->[0] eq 'ARRAY' ){
		return grep{
						$it->[0] == $_->[0] and $it->[1] == $_->[1]
		} @$area;
	}
	# a single tile was passed as area
	else{
		return ( $it->[0] == $area->[0] and $it->[1] == $area->[1] ) ? 1 : 0;
	}	
}

sub is_walkable{
	my $game = shift;
	# ~ copied from UI
	my $tile = shift; #use Data::Dump; dd 'TILE',$tile;
	if ( $game->{configuration}->{terrains}{ $tile->[1] }->[4] < 5 ){ return 1}
	else{return 0}
}

sub execute{
	my $game = shift;
	my ($cmd,@args) = @_;
	# SKIP if the command is a single letter and in command mode
	if( $game->{ui}->{mode} eq 'command' and $cmd =~/^\w$/){
		return;	
	}
	my %table = (
		##############################################
		#	SINGLE LETTER COMMAND WHILE IN MAP MODE
		#   they return 1 if a movement was done
		#	or 0 if not (b for bag, u for use, l for labels?)
		##############################################
		
		# MOVE NORTH
		w => sub{
			if ( 
				# we are inside the real map
				$game->{ui}->{hero_y} > 0 	and
				$game->is_walkable(
					$game->{ui}->{map}->[ $game->{ui}->{hero_y} - 1 ]
										[ $game->{ui}->{hero_x} ]
				)
						
			){
        
				$game->{hero}->{y}--;
				$game->{ui}->{hero_y}--;
				$game->{ui}->{map_off_y}-- if $game->{ui}->must_scroll();				
				# el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
				$game->{ui}->{hero_terrain} = 
				$game->{hero}->{on_tile} 	= 
											$game->{configuration}->{terrains}->
												{$game->{ui}->{map}->
													[ $game->{hero}->{y} ]
													[ $game->{hero}->{x} ]->[1]  
												}->[0];
				# $game->{ui}->draw_map();
				print __PACKAGE__, 
					" HERO on $game->{hero}->{on_tile} ",
					"at y: $game->{ui}->{hero_y} x: $game->{ui}->{hero_x}\n" if $debug;
				
				return 1;
			}
		},
		# MOVE SOUTH
		s => sub{
			if ( 
				# we are inside the real map
				$game->{ui}->{hero_y} < $#{$game->{ui}->{map}} 	and
				$game->is_walkable(
					$game->{ui}->{map}->[ $game->{ui}->{hero_y} + 1 ]
										[ $game->{ui}->{hero_x} ]
				)
						
			){
        
				$game->{hero}->{y}++;
				$game->{ui}->{hero_y}++;
				$game->{ui}->{map_off_y}++ if $game->{ui}->must_scroll();				
				# el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
				$game->{ui}->{hero_terrain} = 
				$game->{hero}->{on_tile} 	= 
											$game->{configuration}->{terrains}->
												{$game->{ui}->{map}->
													[ $game->{hero}->{y} ]
													[ $game->{hero}->{x} ]->[1]  
												}->[0];
				# $game->{ui}->draw_map();
				print __PACKAGE__, 
					" HERO on $game->{hero}->{on_tile} ",
					"at y: $game->{ui}->{hero_y} x: $game->{ui}->{hero_x}\n" if $debug;
				
				return 1;
			}
		},
		# MOVE WEST
		a => sub{
			if ( 
				# we are inside the real map
				$game->{ui}->{hero_x} > 0 	and
				$game->is_walkable(
					$game->{ui}->{map}->[ $game->{ui}->{hero_y} ]
										[ $game->{ui}->{hero_x} - 1 ]
				)
						
			){
        
				$game->{hero}->{x}--;
				$game->{ui}->{hero_x}--;
				$game->{ui}->{map_off_x}-- if $game->{ui}->must_scroll();				
				# el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
				$game->{ui}->{hero_terrain} = 
				$game->{hero}->{on_tile} 	= 
											$game->{configuration}->{terrains}->
												{$game->{ui}->{map}->
													[ $game->{hero}->{y} ]
													[ $game->{hero}->{x} ]->[1]  
												}->[0];
				# $game->{ui}->draw_map();
				print __PACKAGE__, 
					" HERO on $game->{hero}->{on_tile} ",
					"at y: $game->{ui}->{hero_y} x: $game->{ui}->{hero_x}\n" if $debug;
				
				return 1;
			}
		},
		# MOVE EAST
		d => sub{
			if ( 
				# we are inside the real map
				$game->{ui}->{hero_x}  < $#{$game->{ui}->{map}[0]} 	and
				$game->is_walkable(
					$game->{ui}->{map}->[ $game->{ui}->{hero_y} ]
										[ $game->{ui}->{hero_x} + 1 ]
				)
						
			){
        
				$game->{hero}->{x}++;
				$game->{ui}->{hero_x}++;
				$game->{ui}->{map_off_x}++ if $game->{ui}->must_scroll();				
				# el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
				$game->{ui}->{hero_terrain} = 
				$game->{hero}->{on_tile} 	= 
											$game->{configuration}->{terrains}->
												{$game->{ui}->{map}->
													[ $game->{hero}->{y} ]
													[ $game->{hero}->{x} ]->[1]  
												}->[0];
				# $game->{ui}->draw_map();
				print __PACKAGE__, 
					" HERO on $game->{hero}->{on_tile} ",
					"at y: $game->{ui}->{hero_y} x: $game->{ui}->{hero_x}\n" if $debug;
				
				return 1;
			}
		},
		# SHOW BAG
		b => sub{
			$game->show_bag();
			return 0;
		},
		# USE ITEM
		u => sub{
			print ' '.$game->{ui}->{ dec_ver }.
					" enter the number of object to use or return\n";
			$game->show_bag();
			
			my $num = $game->{ui}{reader}->readline('use item number: ');
			return unless defined $num;
			chomp $num;
			$num=~s/\s+$//g;
			if( $num =~/^\d+$/ and defined $game->{hero}{bag}->[$num] ){
				# EFFECT AT NEXT TURN
				push @{$game->{timeline}[ $game->{turn} + 1 ]},
					Game::Term::Event->new( 
							type 		=> 'game turn', 
							check 		=> $game->{turn} + 1, 
							target 		=> 'hero', 
							target_attr => $game->{hero}{bag}->[$num]->{target_attr},
							target_mod 	=> $game->{hero}{bag}->[$num]->{target_mod},
							duration 	=> $game->{hero}{bag}->[$num]->{duration},
							message		=> $game->{hero}{bag}->[$num]->{message},
			
				);
				use Data::Dump; dd "timeline",$game->{timeline};
				# REMOVE if consumable
				undef $game->{hero}{bag}->[$num] if $game->{hero}{bag}->[$num]->{consumable};
				# USE COUNTS AS MOVING
				return 1;
			}
			else{
				print ' '.$game->{ui}->{ dec_ver }.
					" Warning! Not a number or not such item: [$num]\n";
				return 0;
			}
		},
		# HELP
		h => sub{
			my $help =<<'EOH';
			


MAP MODE (exploration)

w   walk north
a   walk west
s   walk south
d   walk east

b   show bag content
u   use an item in the bag (counts as a move)

h   show this help

l   show labels on the map (to be implemented)

:   switch to COMMAND MODE



COMMAND MODE (use TAB to autocomplete commands)

save [filename] 
	save (using YAML) the current game into filename
	or inside a filename crafted on the fly

load filename
	reload the game from a specified save

configuration [filename]
	reload the UI configuration from a YAML file if specified
	or from the default one
	
show_legenda
	show the legenda of the map (to be implemented)
	
return_to_game
	bring you back to MAP MODE
  
EOH

			foreach my $line ( split /\n/,$help ){
				print ' '.$game->{ui}->{ dec_ver }."\t$line\n";
			}
			
		},
		##############################################
		#	LONGER COMMAND WHILE IN COMMAND MODE
		#	they can print to STDOUT
		#	following commands has to be sync with
		#	$term->Attribs->{completion_function} in UI.pm
		##############################################
		
		save=>sub{
			my $filename = shift;
			$filename //= (join'_',split /:|\s+/,$game->{current_scenario}.
							' '.
							scalar localtime(time)).'-save.yaml';
			DumpFile( $filename , $game );
			print "succesfully saved game to $filename\n";
		},
		load=>sub{
			my $filepath = shift;
			unless ($filepath){
				print "provide a file path to load the game from\n";
				return;
			}
			#print "save sub command received: @_\n";
			#<mst> though %{$obj} = %{LoadFile(...)} might be better
			# a big thank to mst for the trick!!!
			%{$game} = %{LoadFile( $filepath )};
			print "succesfully loaded game from a save file\n";
			# local $game->{ui}->{map} = [['fake', 'data']];
			# use Data::Dump; dd $game;#
			$game->{ui}->{mode} = 'map';
			# the below line prevent:Use of freed value in iteration
			# infact we are iterating over actors when reloading $game containing them
			$game->play();
		},
		return_to_game=> sub{ 	
					
					$game->{ui}->{mode}='map'; 
					$game->{ui}->draw_map();
					$game->{ui}->draw_menu( 
								$game->{turn},
								$game->{hero},
								${$game->{messages}}[ $game->{turn}],
					);
					return ;
		},
		show_legenda => sub{ 
					print "to be implemented\n";
		},
		configuration => sub{ 
					my $filepath = shift;
					unless ($filepath){
						print "No file was passed: loading the default one from ".
							"$game->{ui}{from}\n";
						$filepath = $game->{ui}{from};
						
					}
					$game->{ui}->load_configuration( $filepath );
					# ISSUE #30
					# $game->{ui}->init();
					$game->{ui}->beautify_map();
					# end of ISSUE #30
					$game->{ui}->draw_map();
					$game->{ui}->draw_menu( 
								$game->{turn},
								$game->{hero},
								[
									"loaded configurations from $filepath", 
									@{$game->{messages}}[ $game->{turn} ]//'' 
								],
					);
					#return 1;
		},
		
		exit => sub{
			$game->save_game_state();
			exit 0;
		}
	);
	if( $table{$cmd} and exists $table{$cmd} ){ $table{$cmd}->(@args) }
	else{return 0};
}

sub show_bag{
	my $game = shift;
	@{ $game->{hero}{bag} } = grep { defined } @{ $game->{hero}{bag} };
	if( @{ $game->{hero}{bag} } ){
		my $index = 0;
		print ' '.$game->{ui}->{ dec_ver }." * Bag content *\n";
		foreach my $item ( sort @{ $game->{hero}{bag} } ){
			print ' '.$game->{ui}->{ dec_ver }.
					"[$index]\t$item->{name}\n"
		}
	}
	else{
		print ' '.$game->{ui}->{ dec_ver }."Bag is empty\n";
	}	
}

1;
