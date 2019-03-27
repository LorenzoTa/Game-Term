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
		
		
my $valid1 = Game::Term::Map->new( fake_map => 'S' );
ok ( ref $valid1->{data} eq 'ARRAY', "data part of the object is an array (valid fake_map)"); 

my $validAoA = [[1,2],[1,2],[1,2]];
my $valid2 = Game::Term::Map->new( from => $validAoA );
ok ( ref $valid2->{data} eq 'ARRAY', "data part of the object is an array (valid anonymous array)"); 

my @validAoA = ([1,2],[1,2],[1,2]);
my $valid3 = Game::Term::Map->new( from => \@validAoA );
ok ( ref $valid3->{data} eq 'ARRAY', "data part of the object is an array (valid array reference)"); 

