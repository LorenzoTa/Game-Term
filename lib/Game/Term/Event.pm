package Game::Term::Event;

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
	$params{type} //= 'UNKNOWN EVENT TYPE';
	my %valid = (
		'hero at' 	=> 1,
		'game turn' => 1,
	);
	croak "Unknown event type [$params{type}]!" unless exists $valid{ $params{type} };
	return %params;
}


1;
__DATA__