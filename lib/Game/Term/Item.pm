package Game::Term::Item;

use 5.014;
use strict;
use warnings;

use Carp;

sub new{
	my $class = shift;
	my %params = validate_conf(@_);
	return bless {
				%params
	}, $class;
	
}

sub validate_conf{
	my %params = @_;
	croak "Item needs a neme!" unless $params{name};
	$params{consumable} //= 0;
	$params{duration} //= undef;
	
	
	
	return %params;
}


1;
__DATA__