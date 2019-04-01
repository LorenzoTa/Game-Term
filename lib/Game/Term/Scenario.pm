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
	# GET hero..
	# if $param{hero} or ..	
	# if passed a file for the map
	if( $param{map} and -e -f -s $param{map} ){
		$param{map} = Game::Term::Map->new( from => *DATA )->{data};
	}
	# else grab map from DATA
	else{
		while (<DATA>){
			chomp;
			push @{$param{map}},[ split '', $_ ];
		}
	}
	
	return bless {
	
		name => $param{name} // 'scenario name',
		map	=> $param{map},
		creatures => [],
		events	=> [],
				
	}, $class; 

}

__DATA__
S                  S
     tttt  T        
 ttt    tTT t       
    tt    tT        
tttttttttttttttt    
  ttt   tt      nN  
    wW              
         mM   ww    
             wWwW   
TTTTTTTTT           
S        X         S