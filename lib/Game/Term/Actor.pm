package Game::Term::Actor;

use 5.014;
use strict;
use warnings;

sub new{
	my $class = shift;
	my %params = validate_conf(@_);
	return bless {
				%params
	}, $class;
	
}

sub validate_conf{
	my %params = @_;
	$params{name} //= 'unnamed';
	$params{race} //= 'unknown';
	$params{hitpoints} //= 1;
	$params{energy} //= 0;
	$params{max_energy} //= 200;
	$params{energy_gain} = {
		' ' => 40,	# plain
		'#'	=> 0,	# stone
		A 	=> 40,	# bridge
		a 	=> 40,	# bridge
		B 	=> 40,	# bridge
		b	=> 40,	# bridge
		D 	=> 0,	# closed door
		d 	=> 40, 	# door
		h 	=> 30, 	# hill
		M 	=> 0,	# unwalkable mountain
		m 	=> 10, 	# mountain 
		S 	=> 0,	# unwalkable swamp
		s	=> 5, 	# swamp
		T   => 0,	# unwalkable wood
		t 	=> 30, 	# wood
		W 	=>	0,	# deep water
		w	=> 10, 	# shallow water 
		y 	=> 40, 	# pine wood 
	};
	$params{icon} = 'X';
	$params{color} = 'Fuchsia';
	$params{on_tile} //= '';
	$params{x} //= undef;
	$params{y} //= undef;
	
	# ADDED stuf removed from configuration
	$params{sight} //= 5;
	return %params;
}

sub move{
	my $self = shift;
	my $hero_pos = shift; 			# [y,x] of hero
	my $available_moves = shift; 	# [[y0,x0],[y1,x1]...]
	return $available_moves->[ int(rand($#{$available_moves}))];
}


sub automove{
	my $self = shift;
	srand( time + $self->{y} * $self->{x} );#$self->{y}+$self->{x}
	return(
					[$self->{y}+1,$self->{x}],
					[$self->{y}-1,$self->{x}],
					[$self->{y},$self->{x}+1],
					[$self->{y},$self->{x}-1])[int( rand(4) )];

}

1;
__DATA__