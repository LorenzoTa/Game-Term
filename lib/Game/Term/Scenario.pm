package Game::Term::Scenario;

use 5.014;
use strict;
use warnings;

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
	# else grab map from DATA
	# else{
		# while (<DATA>){
			# chomp;
			# push @{$param{map}},[ split '', $_ ];
		# }
	# }
	
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