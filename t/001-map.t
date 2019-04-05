#!perl
use 5.014;
use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use Game::Term::Map;

dies_ok { my $map = Game::Term::Map->new( fake_map => 'not_existing' ); } 
		"expected to die with no existing fake map";

my $fakeAoA = [[1,2],[1,2],[1,2,3]];
#my $map = Game::Term::Map->new( from => $fakeAoA );
dies_ok { my $map = Game::Term::Map->new( from => $fakeAoA ); } 
		"expected to die with AoA of not rectangular shape (anonymous array)";

my @fakeAoA = ([1,2],[1,2],[1,2,3]);
#my $map = Game::Term::Map->new( from => \@fakeAoA );
dies_ok { my $map = Game::Term::Map->new( from => \@fakeAoA ); } 
		"expected to die with AoA of not rectangular shape (array reference)";
		
		
my $validAoA = [[1,2],[1,2],[1,2]];
my $valid2 = Game::Term::Map->new( from => $validAoA );
ok ( ref $valid2->{data} eq 'ARRAY', "data part of the object is an array (valid anonymous array)"); 
ok ( ref $valid2->{data}[0] eq 'ARRAY', "AoA (valid anonymous array)");

my @validAoA = ([1,2],[1,2],[1,2]);
my $valid3 = Game::Term::Map->new( from => \@validAoA );
ok ( ref $valid3->{data} eq 'ARRAY', "data part of the object is an array (valid array reference)"); 
ok ( ref $valid3->{data}[0] eq 'ARRAY', "AoA (valid array reference)"); 

my $valid1 = Game::Term::Map->new( fake_map => 'SMALL' );
ok ( ref $valid1->{data} eq 'ARRAY', "data part of the object is an array (valid fake_map)"); 
ok ( ref $valid1->{data}[0] eq 'ARRAY', "AoA (valid fake_map)");
ok ( $valid1->{data}[0][0] eq '#', "expected first tile (valid fake_map)");
ok ( $valid1->{data}[0][9] eq '#', "expected last, (default sized) tile (valid fake_map)");
ok ( $valid1->{data}[9][0] eq $valid1->{data}[9][9], 
			"expected (default sized) last row tiles (valid fake_map)");

if ( $ENV{TEST_VERBOSE }){
	note"map received:";
	foreach my $row(@{$valid1->{data}}){
		print +(join '', @$row),$/;
	}
}

my $valid4 = Game::Term::Map->new( fake_map => 'SMALL', fake_y => 20, fake_x => 20 );
ok ( $valid1->{data}[19][0] eq $valid1->{data}[19][19], 
			"expected (custom sized) last row tiles (valid fake_map)");




