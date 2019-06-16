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
	#$params{energy_gain} //= 40;
	$params{energy_gain} = {
		' ' => 40,	# plain
		d 	=> 40, 	# door
		h 	=> 30, 	# hill
		m 	=> 10, 	# mountain 
		s	=> 5, 	# swamp
		t 	=> 30, 	# wood 
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