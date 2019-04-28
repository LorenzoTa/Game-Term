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
	$params{hitpoints} //= 1;
	$params{energy} //= 0;
	$params{energy_gain} //= 5;
	$params{energy_gain_multipliers} = {
		h => 0.8, # hill 0.8
		m => 0.3, # mountain 3
		s => 0.1, # swamp 1 
		t => 0.5, # wood 0.5
		w => 0.2, # shallow water 2
		y => 0.5, # wood 0.5 
	};
	$params{icon} = 'X';
	$params{color} = 'Blue';
	$params{on_tile} = ' ';
	$params{x} //= undef;
	$params{y} //= undef;
	return %params;
}

sub automove{
	my $self = shift;
	srand(time);#$self->{y}+$self->{x}
	return(
					[$self->{y}+1,$self->{x}],
					[$self->{y}-1,$self->{x}],
					[$self->{y},$self->{x}+1],
					[$self->{y},$self->{x}-1])[int( rand(4) )];

}

1;
__DATA__