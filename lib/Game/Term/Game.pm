package Game::Term::Game;

use 5.014;
use strict;
use warnings;

use YAML qw(Dump DumpFile LoadFile);


use Game::Term::Configuration;
use Game::Term::UI;

use Game::Term::Actor;
use Game::Term::Actor::Hero;

our $VERSION = '0.01';

sub new{
	my $class = shift;
	my %param = @_;
	# GET hero..
	# if $param{hero} or ..	
	$param{configuration} //= Game::Term::Configuration->new();
	
	$param{scenario} //= Game::Term::Scenario->new( );
	
	$param{ui} //= Game::Term::UI->new( 
										configuration => $param{configuration}, 
										# map => $param{map},
										map => $param{scenario}->{map},
										debug => $param{debug},
										
										);
	$param{scenario}->{map} = undef;
	return bless {
				is_running => 1,
				current_scenario => '',
				hero => $param{hero},
				actors	=> [ 
							Game::Term::Actor->new(name=>'UNO',energy_gain=>2),
							#Game::Term::Actor->new(name=>'DUE',energy_gain=>6) 
							],
				configuration => $param{configuration} ,
				ui	=> $param{ui},
	}, $class;
}

sub play{
	my $game = shift;
	
	$game->{ui}->draw_map();
	$game->{ui}->draw_menu( ["hero HP: 42","walk with WASD or : to enter command mode"] );	

	while($game->{is_running}){
		# COMMAND
		if ($game->{ui}->{mode} and $game->{ui}->{mode} eq 'command' ){
			my @usr_cmd = $game->{ui}->get_user_command();
			next unless @usr_cmd;
			print "in Game.pm 'command' received: [@usr_cmd]\n";
			$game->commands(@usr_cmd);
			next;
		}
		# MAP
		else{
			# FOREACH HERO,ACTORS
			foreach my $actor ( $game->{hero}, @{$game->{actors}} ){ 			
				# ACTOR CAN MOVE
				if ( $actor->{energy} >= 10 and $actor->isa('Game::Term::Actor::Hero') ){
					print join ' ',__PACKAGE__,'play'," DEBUG '$actor->{name}' --> can move\n";
					# PLAYER: GET USER COMMAND	
						
					my @usr_cmd = $game->{ui}->get_user_command();
					next unless @usr_cmd; # ??? last ???
					print "in Game.pm 'map' received: [@usr_cmd]\n";
					
					if ($usr_cmd[0] eq ':'){
						$game->{ui}->{mode} = 'command';
						last;
					}
					
					$game->commands(@usr_cmd) ;
					$actor->{energy} -= 10;
				}	
				# NPC: AUTOMOVE
				elsif( $actor->{energy} >= 10 ){
						print join ' ',__PACKAGE__,'play'," DEBUG '$actor->{name}' --> can move\n";
					
						# $actor->automove() if $actor->can('automove');
						# $game->{ui}->draw_map(); ??
						$actor->{energy} -= 10;					
										
				}
				# CANNOT MOVE
				else{
					$actor->{energy} += $actor->{energy_gain};
					print __PACKAGE__," DEBUG '$actor->{name}' ends with energy $actor->{energy}\n";
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

sub commands{
	my $game = shift;
	my ($cmd,@args) = @_;
	my %table = (
		
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
}




