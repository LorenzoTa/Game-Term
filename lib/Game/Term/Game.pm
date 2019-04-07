package Game::Term::Game;

use 5.014;
use strict;
use warnings;

use YAML qw(Dump DumpFile LoadFile);


use Game::Term::Configuration;
use Game::Term::UI;

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
				hero	=> undef,
				actors	=> [],
				configuration => $param{configuration} ,
				ui	=> $param{ui},
	}, $class;
}

sub play{
	my $game = shift;
	
		$game->{ui}->draw_map();
		$game->{ui}->draw_menu( ["hero HP: 42","walk with WASD or : to enter command mode"] );	

	
	while($game->{is_running}){
		# update energy for [hero, actors]
		# if hero's energy is enough
		my @ret = $game->{ui}->show();
		print "in Game.pm received: [@ret]\n";
		$game->commands(@ret);
	}
}

sub commands{
	my $game = shift;
	my ($cmd,@args) = @_;
	my %table = (
	
		save=>sub{
			#print "save sub command received: @_\n";
			DumpFile( $_[0], $game );
		},
		load=>sub{
			#print "save sub command received: @_\n";
			$game = LoadFile( $_[0] );
			
			local $game->{ui}->{map} = [['fake', 'data']];
			use Data::Dump; dd $game;#
		},
	);
	if( exists $table{$cmd} ){ $table{$cmd}->(@args) }
}




