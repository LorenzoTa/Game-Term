package Game::Term::Game;

use 5.014;
use strict;
use warnings;

use Game::Term::Configuration;
use Game::Term::UI;

our $VERSION = '0.01';

sub new{
	my $class = shift;
	my %param = @_;
	# GET hero..
	# if $param{hero} or ..	
	$param{configuration} //= Game::Term::Configuration->new();
	
	# $param{ui} //= Game::Term::UI->new( configuration => $param{configuration} );
	
	$param{ui} //= Game::Term::UI->new( configuration => $param{configuration}, map => $param{map} );
	
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
		$game->{ui}->draw_menu( ["hero HP: 42","walk with WASD"] );	

	
	while($game->{is_running}){
		# update energy for [hero, actors]
		# if hero's energy is enough
		$game->{ui}->show();
	}
}






