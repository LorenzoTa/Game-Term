package Game::Term::Game;

use 5.014;
use strict;
use warnings;

use YAML qw(Dump DumpFile LoadFile);
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
	
	return bless {
				is_running => 1,
				
				configuration => $param{configuration} ,
				
				scenario => $param{scenario},
				current_scenario => $param{scenario}->{name},
				
				ui	=> $param{ui},
				
				hero => $param{hero},
				actors	=> [
							@actors
							#Game::Term::Actor->new(name=>'UNO',energy_gain=>2),
							#Game::Term::Actor->new(name=>'DUE',energy_gain=>6) 
							],
				
				
	}, $class;
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
			$game->commands(@usr_cmd);
			next;
		}
		# MAP
		else{
			# FOREACH HERO,ACTORS
			foreach my $actor ( $game->{hero}, @{$game->{actors}} ){ 			
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
					if ( $game->commands(@usr_cmd) ){
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
								"$game->{hero}{name} at y: $game->{hero}{y} ".
								"x: $game->{hero}{x} ($game->{hero}{on_tile})",] 
						);	
						$actor->{energy} -= 10;
					}
					# NO movement 
					else{print "DEBUG: no hero move\n"; redo}
				}	
				# NPC: AUTOMOVE
				elsif( $actor->{energy} >= 10 ){
						print join ' ',__PACKAGE__,'play'," DEBUG '$actor->{name}' --> can move\n" if $debug;
					
						my $newpos = $actor->automove() if $actor->can('automove');
						if(	
							$newpos and 
							$$newpos[0] >= 0 and 
							$$newpos[0] <= $#{$game->{ui}->{map}} and
							$$newpos[1] >= 0 and
							$$newpos[1] <= $#{$game->{ui}->{map}[0]} and
							$game->is_walkable(
								$game->{ui}->{map}->[ $$newpos[0] ]
													[ $$newpos[1] ]
							)
						){
							$actor->{y} = $$newpos[0];
							$actor->{x} = $$newpos[1];
							#$game->{ui}->draw_map(  @{$game->{actors}}  );
							$actor->{energy} -= 10;
							print "$actor->{name} at y: $actor->{y} / 0-$#{$game->{ui}->{map}} x: $actor->{x} / $#{$game->{ui}->{map}[0]}\n";
						}
						# NO ACTOR movement 
						else{	#print "DEBUG: no actor movement\n"; 
								redo;
						}				
										
				}
				# CANNOT MOVE
				else{
					$actor->{energy} += $actor->{energy_gain};
					print __PACKAGE__," DEBUG '$actor->{name}' ends with energy $actor->{energy}\n" if $debug;
				}
			
			}
		}
	
	}
}

sub playORIGINAL{
	my $game = shift;
	
		$game->{ui}->draw_map();
		$game->{ui}->draw_menu( ["hero HP: 42","walk with WASD or : to enter command mode"] );	

		while($game->{is_running}){
		# update energy for [hero, actors]
		# if hero's energy is enough
	
		foreach my $actor ( $game->{hero}, @{$game->{actors}} ){ # , @{$game->{actors}}
			$actor->{energy} += $actor->{energy_gain};
			print __PACKAGE__," DEBUG '$actor->{name}' energy $actor->{energy}\n";
			
			if ( $actor->{energy} >= 10 ){
				print join ' ',__PACKAGE__,'play'," DEBUG '$actor->{name}' --> can move\n";
				$actor->{energy} -= 10;
				
				if ( $actor->isa('Game::Term::Actor::Hero') ){
					my @ret = $game->{ui}->show(); #<-------------------
					print "in Game.pm received: [@ret]\n";
					$game->commands(@ret);
				}
				#else{$game->{ui}->draw_map();}
			}
		}
		
		
		# my @ret = $game->{ui}->show();
		# #print "in Game.pm received: [@ret]\n";
		# $game->commands(@ret);
	}
}
sub is_walkable{
	my $game = shift;
	# ~ copied from UI
	my $tile = shift; 
	if ( $game->{configuration}->{terrains}{ $tile->[1] }->[4] < 5 ){ return 1}
	else{return 0}
}
sub commands{
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
	);
	if( $table{$cmd} and exists $table{$cmd} ){ $table{$cmd}->(@args) }
	else{return 0};
}



1;
