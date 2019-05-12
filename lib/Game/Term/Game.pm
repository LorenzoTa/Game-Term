package Game::Term::Game;

use 5.014;
use strict;
use warnings;

use File::Spec;
use YAML::XS qw(Dump DumpFile LoadFile);
use Storable qw(store retrieve);
use Time::HiRes qw ( sleep );

use Game::Term::Configuration;
use Game::Term::UI;

use Game::Term::Actor;
use Game::Term::Actor::Hero;

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
	
	# check saved scenario data (creatures and map)!!
	my @actors = @{$param{scenario}->{creatures}};
	#use Data::Dump; dd $param{scenario};
	$param{scenario}->{creatures} = undef;
	
	my $game = bless {
				is_running => 1,
				
				configuration => $param{configuration} ,
				
				# scenario => $param{scenario}, ### ??????
				current_scenario => $param{scenario}->{name},
				
				ui	=> $param{ui},
				
				hero => $param{hero},
				actors	=> [ @actors ],
				
				turn => 0,
				
				
	}, $class;
	# load and overwrite info about hero and current scenario(map,creatures,..)from gamestate.sto
	$game->get_game_state();
	
	return $game;
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
		#use Data::Dump; dd $game_state if $debug;
		
		# eventually LOAD data of the current scenario
		if(	$$game_state->{ $game->{current_scenario} } ){
			print "DEBUG: loaded data of '$game->{current_scenario}' from $state_file\n" 
				if $debug;
			# LOAD actors
			$game->{actors} = $$game_state->{ $game->{current_scenario} }{actors};
			# LOAD map
			$game->{ui}->{map} = $$game_state->{ $game->{current_scenario} }{map};
		}
		else{
			print "DEBUG: no data of '$game->{current_scenario}' in $state_file\n" if $debug;
		}		
	}
	# GameState.sto does not exists
	else {
		print "DEBUG: $state_file not found\n" if $debug;
		# create with just hero inside
		$game_state = { hero => $game->{hero} };
		die unless store ( \$game_state, $state_file );
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
		# dd $game_state if $debug;
		# print "DEBUG: \$game_state ref: ",ref($$game_state),"\n";
	}
	# GameState.sto does not exists
	else {
		print "DEBUG: $state_file not found: a new one will be created\n" if $debug;
		$game_state = {};
	}
	# populate GameState.sto with the structure
	$$game_state->{ hero } = $game->{hero};
	$$game_state->{ $game->{current_scenario} } = {
						map 		=> $game->{ui}->{map},
						actors 	=> $game->{actors},
	};
	
	die unless store ( $game_state, $state_file );
	
	DumpFile( $state_file.'.yaml', $game_state ) if $debug;
	
}

sub play{
	my $game = shift;
	#INIT
	$game->{hero}->{y} = $game->{ui}->{hero_y};
	$game->{hero}->{x} = $game->{ui}->{hero_x};
	# ?? opposite: hero->on_tile = map
	# $game->{ui}->{map}[$game->{hero}->{y}][$game->{hero}->{x}] = [ " \e[0m",' ',0];
	$game->{ui}->draw_map();
	$game->{ui}->draw_menu( ["hero HP: 42","walk with WASD or : to enter command mode"] );	

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
							$game->{ui}->{hero_slowness} + 
							# the slowness #4 of the terrain original letter #1 where
							# the hero currently is on the map
							$game->{configuration}->{terrains}->{$game->{ui}->{map}->[ $game->{hero}->{y} ][ $game->{hero}->{x} ]->[1]}->[4]
						);
						# sigth modifications
						local $game->{ui}->{hero_sight} = $game->{ui}->{hero_sight} + 2 
							if $game->{ui}->{hero_terrain} eq 'hill';
						local $game->{ui}->{hero_sight}  = $game->{ui}->{hero_sight} + 4 
							if $game->{ui}->{hero_terrain} eq 'mountain';
						local $game->{ui}->{hero_sight} = $game->{ui}->{hero_sight} - 2 
							if $game->{ui}->{hero_terrain} eq 'wood';
						
						
						# draw screen (passing creatures)
						$game->{ui}->draw_map(  @{$game->{actors}}  );
						$game->{ui}->draw_menu( 
							[	"walk with WASD or : to enter command mode",
								"(turn: $game->{turn}) $game->{hero}{name} at y: $game->{hero}{y} ".
								"x: $game->{hero}{x} ($game->{hero}{on_tile})",] 
						);	
						$actor->{energy} -= 10;
					}
					# NO movement 
					else{
							print "DEBUG: no hero move\n"; 
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

sub check_events{
	my $game = shift;
	print "DEBUG: checking events at turn $game->{turn}..\n";
	
	
	return;

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
	my %table = (
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
		save=>sub{
			#print "save sub command received: @_\n";
			DumpFile( $_[0], $game );
			print "succesfully saved game to $_[0]\n";
		},
		load=>sub{
			#print "save sub command received: @_\n";
			#<mst> though %{$obj} = %{LoadFile(...)} might be better
			# a big thank to mst for the trick!!!
			%{$game} = %{LoadFile( $_[0] )};
			print "succesfully loaded game from a save file\n";
			# local $game->{ui}->{map} = [['fake', 'data']];
			# use Data::Dump; dd $game;#
			$game->{ui}->{mode} = 'map';
			# the below line prevent:Use of freed value in iteration
			# infact we are iterating over actors when reloading $game containing them
			$game->play();
		},
		exit => sub{
			$game->save_game_state();
			exit 0;
		}
	);
	if( $table{$cmd} and exists $table{$cmd} ){ $table{$cmd}->(@args) }
	else{return 0};
}



1;
