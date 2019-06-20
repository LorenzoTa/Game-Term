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
	$param{scenario}->{actors} = undef;
	my @events = @{$param{scenario}->{events}};
	$param{scenario}->{events} = undef;
	my @labels = @{$param{scenario}->{labels}};
	$param{scenario}->{labels} = undef;
	
	my $game = bless {
				is_running => 1,				
				configuration => $param{configuration} ,				
				current_scenario => $param{scenario}->{name},				
				ui		=> $param{ui},				
				hero 	=> $param{hero},
				actors	=> [ @actors ],				
				events	=> [ @events ],
				labels 	=> [ @labels ],
				timeline=> [],				
				messages=> [],				
				turn 	=> 0,				
	}, $class;

	
	# beautify the map (not hero!) and others..
	$game->{ui}->init();
	# retrieve hero, actors,events and apply MASK now!
	$game->get_game_state();
	# INJECT into UI HERO now!
	$game->{ui}->{ hero } = $game->{ hero };
	# let CONFIGURATION to overwrite hero's COLOR
	if ( $game->{configuration}{interface}{hero_color} ){
		$game->{hero}->{color} = $game->{configuration}{interface}{hero_color};
	}
	# let CONFIGURATION to overwrite hero's ICON
	if ( $game->{configuration}{interface}{hero_icon} ){
		$game->{hero}->{icon} = $game->{configuration}{interface}{hero_icon};
	}
	# BEAUTIFY HERO
	unless ( ref $game->{hero}{icon} eq 'ARRAY' ){
		$game->{hero}{icon} = [ 
								$game->{ui}->color_names_to_ANSI($game->{hero}->{color}).	# to DISPLAY
																	$game->{hero}{icon}.
												$game->{ui}->color_names_to_ANSI('reset'), 	
								$game->{hero}{icon}, 										# original
								1                                 							# masked ??
		];
	}
	
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

	$game->{ui}->draw_map( @{$game->{actors}} );
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
				my $consumed_energy;
				# ACTOR CAN MOVE
				if ( $actor->{energy} >= 100 and $actor->isa('Game::Term::Actor::Hero') ){
					# LIMIT energy to max_energy
					$actor->{energy} = $actor->{max_energy}
						if $actor->{energy} > $actor->{max_energy};
						
					print join ' ',__PACKAGE__,'play'," DEBUG '$actor->{name}' --> can move\n"
						 if $debug;
					print "DEBUG '$actor->{name}' has energy: $actor->{energy}\n"
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
					if ( $consumed_energy = $game->execute(@usr_cmd) ){
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
						) if $consumed_energy > 0;
						# sigth modifications
						#local $game->{hero}{sight} = $game->{hero}{sight} + 2 

						local $game->{hero}{sight} = $game->{hero}{sight} + 2 
							if $game->{hero}{on_tile} eq 'hill';
						local $game->{hero}{sight}  = $game->{hero}{sight} + 4 
							if $game->{hero}{on_tile} eq 'mountain';
						local $game->{hero}{sight} = $game->{hero}{sight} - 2 
							if $game->{hero}{on_tile} eq 'wood';
												
						# draw screen (passing actors)
						$game->{ui}->draw_map(  @{$game->{actors}}  );
						$game->{ui}->draw_menu( 
							$game->{turn},
							$game->{hero},
							${$game->{messages}}[ $game->{turn}],
						);	
						$actor->{energy} -= $consumed_energy;
					}
					# NO movement 
					else{
							print "DEBUG: no hero move\n" if $debug; 
							redo;
					}
				}	
				# NPC: AUTOMOVE
				elsif( $actor->{energy} >= 100 ){
						# LIMIT energy to max_energy
						$actor->{energy} = $actor->{max_energy}
							if $actor->{energy} > $actor->{max_energy};
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
			$consumed_energy = 50;
						# DRAW MAP only if actor is in sight range
						my %visible = $game->{ui}->illuminate();
						if ( exists $visible{ $actor->{y}.'_'.$actor->{x} } ){
							print "$actor->{name} in SIGHT!!\n" if $debug;
							$game->message( "$actor->{name} in SIGHT!!");
							
							$game->{ui}->draw_map(  @{$game->{actors}}  );
							$game->{ui}->draw_menu( 
								$game->{turn},
								$game->{hero},
								${$game->{messages}}[ $game->{turn}],
							);
						}
						#$actor->{energy} -= 50;
						$actor->{energy} -= $consumed_energy;
						print "$actor->{name} at y: $actor->{y} / 0-$#{$game->{ui}->{map}} x: $actor->{x} / 0-$#{$game->{ui}->{map}[0]}\n" if $debug;
									
				}
				# CANNOT MOVE
				else{
					#$actor->{energy} += $actor->{energy_gain};
			# print "$actor->{name} on TILE: ->",$game->{ui}->{map}->[ $actor->{y} ][ $actor->{x} ]->[1],"<-\n";
			# dd $actor->{energy_gain};
			
					$actor->{energy} +=
						$actor->{energy_gain}{
							$game->{ui}->{map}->[ $actor->{y} ][ $actor->{x} ]->[1]
							
						};
			
			
					print __PACKAGE__," DEBUG '$actor->{name}' ends with energy $actor->{energy}\n" if $debug;
			#my $dummy = <STDIN>;
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
	push @{ $game->{messages}[ $game->{turn} ] }, "$game->{hero}{y}-$game->{hero}{x}\t$msg";
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
			print "DEBUG: skipping unmanaged event type: [$ev->{type}]\n" if $debug;
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
			push @{$game->{timeline}[ $game->{turn} + $ev->{duration} ]}, 
				Game::Term::Event->new( 
						type 	=> 'game turn', 
						check 	=> $game->{turn} + $ev->{duration} , 
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

sub is_inside_map{
	my $game = shift;
	my ($y,$x) = @_;
	if(
		$y >= 0 					and
		$y <= $#{ $game->{ui}{map} } 	and 
		$x >= 0						and
		$x <= $#{ $game->{ui}{map}[$y] }
		){
			return 1;
	}
	else{ return 0 }
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
		#   they return energy consumed
		#	or 0 if not (b for bag, u for use, l for labels)
		##############################################
		
		# MOVE NORTH
		w => sub{
			if ( 
				# we are inside the real map
				$game->is_inside_map( $game->{hero}{y} - 1, $game->{hero}{x} )	and
				# intended destination has an energy_gain > 0 (is walkable)
				$game->{hero}{energy_gain}{
											$game->{ui}->{map}->[ $game->{hero}{y} - 1 ]
											[ $game->{hero}{x} ]->[1]
										} > 0						
			){
				# print "Energy gain for terrain [".
					# $game->{ui}->{map}->[ $game->{hero}{y} - 1 ][ $game->{hero}{x} ]->[1].
					# "] is ".
					# $game->{hero}{energy_gain}{$game->{ui}->{map}->[ $game->{hero}{y} - 1 ][ $game->{hero}{x} ]->[1]}."\n";
        		$game->{hero}{y}--;
				$game->{ui}->{map_off_y}-- if $game->{ui}->must_scroll();				
				# el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
				$game->{hero}->{on_tile} 	= 
											$game->{configuration}->{terrains}->
												{$game->{ui}->{map}->
													[ $game->{hero}{y} ]
													[ $game->{hero}{x} ]->[1]  
												}->[0];
				print __PACKAGE__, 
					" HERO on $game->{hero}->{on_tile} ",
					"at y: $game->{hero}{y} x: $game->{hero}{x}\n" if $debug;
				
				return 50;
			}
		},
		# MOVE SOUTH
		s => sub{
			if ( 
				# we are inside the real map
				$game->is_inside_map( $game->{hero}{y} + 1, $game->{hero}{x} )	and
				# intended destination has an energy_gain > 0 (is walkable)
				$game->{hero}{energy_gain}{
											$game->{ui}->{map}->[ $game->{hero}{y} + 1 ]
											[ $game->{hero}{x} ]->[1]
										} > 0						
			){
        
				$game->{hero}{y}++;
				$game->{ui}->{map_off_y}++ if $game->{ui}->must_scroll();				
				# el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
				$game->{hero}{on_tile} 	= 
										$game->{configuration}->{terrains}->
											{$game->{ui}->{map}->
												[ $game->{hero}{y} ]
												[$game->{hero}{x} ]->[1]  
											}->[0];
				print __PACKAGE__, 
					" HERO on $game->{hero}->{on_tile} ",
					"at y: $game->{hero}{y} x: $game->{hero}{x}\n" if $debug;
				
				return 50;
			}
		},
		# MOVE WEST
		a => sub{
			if ( 
				# we are inside the real map
				$game->is_inside_map( $game->{hero}{y}, $game->{hero}{x} - 1 )	and
				# intended destination has an energy_gain > 0 (is walkable)
				$game->{hero}{energy_gain}{
											$game->{ui}->{map}->[ $game->{hero}{y} ]
											[ $game->{hero}{x} - 1 ]->[1]
										} > 0						
			){
        
				$game->{hero}{x}--;
				$game->{ui}->{map_off_x}-- if $game->{ui}->must_scroll();				
				# el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
				$game->{hero}{on_tile} 	= 
											$game->{configuration}->{terrains}->
												{$game->{ui}->{map}->
													[ $game->{hero}{y} ]
													[ $game->{hero}{x} ]->[1]  
												}->[0];
				print __PACKAGE__, 
					" HERO on $game->{hero}->{on_tile} ",
					"at y: $game->{hero}{y} x: $game->{hero}{x}\n" if $debug;
				
				return 50;
			}
		},
		# MOVE EAST
		d => sub{
			if ( 
				# we are inside the real map
				$game->is_inside_map( $game->{hero}{y}, $game->{hero}{x} + 1)	and
				# intended destination has an energy_gain > 0 (is walkable)
				$game->{hero}{energy_gain}{
											$game->{ui}->{map}->[ $game->{hero}{y} ]
											[ $game->{hero}{x} + 1 ]->[1]
										} > 0						
			){
				$game->{hero}{x}++;
				$game->{ui}->{map_off_x}++ if $game->{ui}->must_scroll();				
				# el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
				$game->{hero}{on_tile} 	= 
											$game->{configuration}->{terrains}->
												{$game->{ui}->{map}->
													[ $game->{hero}{y} ]
													[ $game->{hero}{x} ]->[1]  
												}->[0];
				print __PACKAGE__, 
					" HERO on $game->{hero}{on_tile} ",
					"at y: $game->{hero}{y} x: $game->{hero}{x}\n" if $debug;
				
				return 50;
			}
		},
		# MOVE NORTH-WEST
		q => sub{
			if ( 
				# we are inside the real map
				$game->is_inside_map( $game->{hero}{y} - 1, $game->{hero}{x} - 1 )	and
				# intended destination has an energy_gain > 0 (is walkable)
				$game->{hero}{energy_gain}{
											$game->{ui}->{map}->[ $game->{hero}{y} - 1 ]
											[ $game->{hero}{x} - 1 ]->[1]
										} > 0						
			){
				$game->{hero}{y}--;
				$game->{hero}{x}--;
				$game->{ui}->{map_off_y}-- if $game->{ui}->must_scroll();
				$game->{ui}->{map_off_x}-- if $game->{ui}->must_scroll();				
				# el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
				$game->{hero}{on_tile} 	= 
											$game->{configuration}->{terrains}->
												{$game->{ui}->{map}->
													[ $game->{hero}{y} ]
													[ $game->{hero}{x} ]->[1]  
												}->[0];
				print __PACKAGE__, 
					" HERO on $game->{hero}{on_tile} ",
					"at y: $game->{hero}{y} x: $game->{hero}{x}\n" if $debug;
				
				return 70;
			}
		},
		# MOVE NORTH-EAST
		e => sub{
			if ( 
				# we are inside the real map
				$game->is_inside_map( $game->{hero}{y} - 1, $game->{hero}{x} + 1 )	and
				# intended destination has an energy_gain > 0 (is walkable)
				$game->{hero}{energy_gain}{
											$game->{ui}->{map}->[ $game->{hero}{y} - 1 ]
											[ $game->{hero}{x} + 1 ]->[1]
										} > 0						
			){
				$game->{hero}{y}--;
				$game->{hero}{x}++;
				$game->{ui}->{map_off_y}-- if $game->{ui}->must_scroll();
				$game->{ui}->{map_off_x}++ if $game->{ui}->must_scroll();				
				# el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
				$game->{hero}{on_tile} 	= 
											$game->{configuration}->{terrains}->
												{$game->{ui}->{map}->
													[ $game->{hero}{y} ]
													[ $game->{hero}{x} ]->[1]  
												}->[0];
				print __PACKAGE__, 
					" HERO on $game->{hero}{on_tile} ",
					"at y: $game->{hero}{y} x: $game->{hero}{x}\n" if $debug;
				
				return 70;
			}
		},
		# MOVE SOUTH-WEST
		z => sub{
			if ( 
				# we are inside the real map
				$game->is_inside_map( $game->{hero}{y} + 1, $game->{hero}{x} - 1 )	and
				# intended destination has an energy_gain > 0 (is walkable)
				$game->{hero}{energy_gain}{
											$game->{ui}->{map}->[ $game->{hero}{y} + 1 ]
											[ $game->{hero}{x} - 1 ]->[1]
										} > 0						
			){
				$game->{hero}{y}++;
				$game->{hero}{x}--;
				$game->{ui}->{map_off_y}++ if $game->{ui}->must_scroll();
				$game->{ui}->{map_off_x}-- if $game->{ui}->must_scroll();				
				# el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
				$game->{hero}{on_tile} 	= 
											$game->{configuration}->{terrains}->
												{$game->{ui}->{map}->
													[ $game->{hero}{y} ]
													[ $game->{hero}{x} ]->[1]  
												}->[0];
				print __PACKAGE__, 
					" HERO on $game->{hero}{on_tile} ",
					"at y: $game->{hero}{y} x: $game->{hero}{x}\n" if $debug;
				
				return 70;
			}
		},
		# MOVE SOUTH-EAST
		x => sub{
			if ( 
				# we are inside the real map
				$game->is_inside_map( $game->{hero}{y} + 1, $game->{hero}{x} + 1 )	and
				# intended destination has an energy_gain > 0 (is walkable)
				$game->{hero}{energy_gain}{
											$game->{ui}->{map}->[ $game->{hero}{y} + 1 ]
											[ $game->{hero}{x} + 1 ]->[1]
										} > 0						
			){
				$game->{hero}{y}++;
				$game->{hero}{x}++;
				$game->{ui}->{map_off_y}++ if $game->{ui}->must_scroll();
				$game->{ui}->{map_off_x}++ if $game->{ui}->must_scroll();				
				# el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
				$game->{hero}{on_tile} 	= 
											$game->{configuration}->{terrains}->
												{$game->{ui}->{map}->
													[ $game->{hero}{y} ]
													[ $game->{hero}{x} ]->[1]  
												}->[0];
				print __PACKAGE__, 
					" HERO on $game->{hero}{on_tile} ",
					"at y: $game->{hero}{y} x: $game->{hero}{x}\n" if $debug;
				
				return 70;
			}
		},
		# REST
		r => sub{
			my $gain = $game->{hero}{energy_gain}{
							$game->{ui}->{map}->[ $game->{hero}{y} ]
											[ $game->{hero}{x} ][1]
						};
			# return NEGATIVE consumed energy
			return 0-$gain;
		},
		# SHOW BAG
		b => sub{
			$game->show_bag();
			return 0;
		},
		# USE ITEM
		u => sub{
			if ( $game->show_bag() ){
				print ' '.$game->{ui}->{ dec_ver }.
					" enter the number of object to use or return\n";
			}
			else{ return 0 }
			
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
				dd "timeline",$game->{timeline} if $debug > 1;
				# REMOVE if consumable
				undef $game->{hero}{bag}->[$num] if $game->{hero}{bag}->[$num]->{consumable};
				# USE COUNTS AS MOVING
				return 10;
			}
			else{
				print ' '.$game->{ui}->{ dec_ver }.
					" Warning! Not a number or not such item: [$num]\n";
				return 0;
			}
		},
		# MESSAGES
		m => sub{
			print ' '.$game->{ui}->{ dec_ver }." * Message History *\n";
			foreach my $turn ( 0..$#{ $game->{messages}} ){
				foreach my $msg ( @{$game->{messages}->[$turn]} ){
					print ' '.$game->{ui}->{ dec_ver }.
							" turn $turn\t$msg\n"
				}
			}
			return 0;
		},
		# LABELS 
		l => sub{
			# get area of currently hero's seen tiles (by coords)
			my %seen = $game->{ui}->illuminate();
			# LOCALIZING
			my @actors = @{$game->{actors}};
			my $index = 0;
			LOOP_ACTORS:
			# actor's tile localized to  their ICON
			local $game->{ui}->{map}[ $actors[$index]->{y} ][ $actors[$index]->{x} ][0] 
				= 
			$game->{ui}->color_names_to_ANSI($actors[$index]->{color}).
			$actors[$index]->{icon}.
			$game->{ui}->color_names_to_ANSI( 'reset' )
			if $actors[$index] and exists $seen{ $actors[$index]->{y}.'_'.$actors[$index]->{x} };
			
			# localize actors LABELS -- OK version
			local @{$game->{ui}->{map}[ $actors[$index]{y}+1 ]}
						[ $actors[$index]{x}..$actors[$index]{x}+length($actors[$index]{name})-1 ]	
			=
			map{[$_,'_',1]}(split //,$actors[$index]->{name})
			if 	#$ui->{map_labels}												and
				$actors[$index] 												and 
				exists $seen{ $actors[$index]{y}.'_'.$actors[$index]{x} }	 	and
				$actors[$index]{y}+1 <= $game->{ui}->{map_off_y} + $game->{ui}->{map_area_h} 	and
				$actors[$index]{x}+length($actors[$index]->{name})-1 < $game->{ui}->{map_off_x} + $game->{ui}->{map_area_w};
			
			
			$index++; 
			goto LOOP_ACTORS if $index <= $#actors;
			
			# scenario LABELS
			my @labels = @{$game->{labels}};
			my $label_index = 0;
			LOOP_PLACES:
			
			local @{$game->{ui}->{map}[ $labels[$label_index]->[0] ]}
						[ $labels[$label_index][1]..$labels[$label_index][1]+length($labels[$label_index][2])-1 ]	
			=
			map{[$_,'_',1]}(split //,$labels[$label_index]->[2])
			if 	
				$labels[$label_index] 												and 
				$game->{ui}{map}[ $labels[$label_index][0] ][$labels[$label_index][1]][2]	 	and
				$labels[$label_index][0] <= $game->{ui}->{map_off_y} + $game->{ui}->{map_area_h} 	and
				$labels[$label_index][1]+length($labels[$label_index][2])-1 < $game->{ui}->{map_off_x} + $game->{ui}->{map_area_w};
			
			$label_index++; 
			goto LOOP_PLACES if $label_index <= $#labels;
			#
			$game->{ui}->draw_map( @{$game->{actors}} );
			$game->{ui}->draw_menu( 
							$game->{turn},
							$game->{hero},
							${$game->{messages}}[ $game->{turn}],
			);
			return 0;
		},
		# HELP
		h => sub{
			my $help =<<'EOH';
			


MAP MODE (exploration)

w   walk north
a   walk west
s   walk south
d   walk east
q   walk northwest
e   walk northeast
z   walk southwest
x   walk southeast
r 	rest

b   show bag content
u   use an item in the bag (counts as a move)

h   show this help

l   show labels on the map

m   show message history

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
			return 0;
		},
		##############################################
		#	LONGER COMMAND WHILE IN COMMAND MODE #LABEL2
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
					return 0;
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
					
					# let CONFIGURATION reload hero's ICON
					my $prev_icon = $game->{hero}{icon}->[1];
					unless ( $prev_icon eq $game->{ui}->{hero_icon} ){
						$prev_icon = $game->{ui}->{hero_icon};
					}
					# let CONFIGURATION reload hero's COLOR
					$game->{hero}{icon} = [ 
								$game->{ui}->color_names_to_ANSI($game->{ui}->{hero_color}).	# to DISPLAY
																				$prev_icon.
												 $game->{ui}->color_names_to_ANSI('reset'), 
								$prev_icon, 													# original
								1                                 								# masked ??
					];
					# REDRAW
					$game->{ui}->draw_map();
					$game->{ui}->draw_menu( 
								$game->{turn},
								$game->{hero},
								[
									"loaded configurations from $filepath", 
									@{$game->{messages}}[ $game->{turn} ]//'' 
								],
					);
					return 0;
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
					"[$index]\t$item->{name}\n";
			$index++;
		}
		return 1;
	}
	else{
		print ' '.$game->{ui}->{ dec_ver }."Bag is empty\n";
		return 0;
	}	
}

1;
