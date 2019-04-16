package Game::Term::Scenario;

use 5.014;
use strict;
use warnings;
use Carp;
use Game::Term::Map;

our $VERSION = '0.01';

# base class for all scenarios

sub new{
	my $class = shift;
	my %param = @_;
	
	# if passed a file for the map
	if( $param{map} and -e -f -s $param{map} ){ # from_file ????
		$param{map} = Game::Term::Map->new( from => $param{map} )->{data};
	}
	
	my $scn = bless {
	
		name => $param{name} // 'scenario name',
		map	=> $param{map},
		creatures => [],
		events	=> [],
				
	}, $class; 

	$scn->get_map_from_DATA() unless ref $scn->{map} eq 'ARRAY';
	
	return $scn;
}

sub get_map_from_DATA{
	my $scn = shift;
	while (<main::DATA>){
			chomp;
			push @{ $scn->{map} },[ split '', $_ ];
	}
}

sub set_hero_position{
	my $scn = shift;
	my $input = shift;
	my ( $side, $position);
	if ( $input =~ /^(south|north|east|west)(\d+)$/i ){
		$side = $1;
		$position = $2;
	}
	else{ croak "unable to parse hero position from string [$input] (expecting something like south13 or west25)"}
	
	if ( $side =~ /north/i ){
		croak "Hero outside map! ". 
				"Valid positions: 0-$#{$scn->{map}[0]} and $position was given"
				if $position > $#{$scn->{map}[0]};
		$scn->{map}[0][$position] = 'X';
		return;
	}
	elsif ( $side =~ /south/i ){
		croak "Hero outside map! ". 
				"Valid positions: 0-$#{$scn->{map}[0]} and $position was given"
				if $position > $#{$scn->{map}[0]};
		$scn->{map}[ $#{$scn->{map}}  ][$position] = 'X';
		return;
	}
	elsif ( $side =~ /east/i ){
		croak "Hero outside map! ". 
				"Valid positions: 0-$#{$scn->{map}} and $position was given"
				if $position > $#{$scn->{map}};
		$scn->{map}[ $position ][ $#{$scn->{map}[0]} ] = 'X';
		return;
	}
	elsif ( $side =~ /west/i ){
		croak "Hero outside map! ". 
				"Valid positions: 0-$#{$scn->{map}} and $position was given"
				if $position > $#{$scn->{map}};
		$scn->{map}[ $position ][ 0 ] = 'X';
		return;
	}
	else{die "something wrong in hero's position!"}
	
	
}
__DATA__
S                  S
     tttt  T        
 ttt    tTT t       
    tt    tT        
tttttttttttttttt    
  ttt   tt      mM  
    wW              
         mM   ww    
             wWwW   
TTTTTTTTT           
S        X         S