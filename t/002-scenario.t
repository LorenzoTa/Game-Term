#!perl
use 5.014;
use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
#use File::Spec;
use Game::Term::Map;
use Game::Term::Scenario;


dies_ok { 
			my $scenario = Game::Term::Scenario->new( 
				map => Game::Term::Map->new( fake_map => 'not_existing' )->data
			)
		}
		"expected to die with no existing fake map";



# dies_ok { my $map = Game::Term::Map->new( fake_map => 'not_existing' ); } 
		# "expected to die with no existing fake map";

# my $fakeAoA = [[1,2],[1,2],[1,2,3]];
# #my $map = Game::Term::Map->new( from => $fakeAoA );
# dies_ok { my $map = Game::Term::Map->new( from => $fakeAoA ); } 
		# "expected to die with AoA of not rectangular shape (anonymous array)";

# my @fakeAoA = ([1,2],[1,2],[1,2,3]);
# #my $map = Game::Term::Map->new( from => \@fakeAoA );
# dies_ok { my $map = Game::Term::Map->new( from => \@fakeAoA ); } 
		# "expected to die with AoA of not rectangular shape (array reference)";
		
		
# my $validAoA = [[1,2],[1,2],[1,2]];
# my $valid2 = Game::Term::Map->new( from => $validAoA );
# ok ( ref $valid2->{data} eq 'ARRAY', "data part of the object is an array (valid anonymous array)"); 
# ok ( ref $valid2->{data}[0] eq 'ARRAY', "AoA (valid anonymous array)");

# my @validAoA = ([1,2],[1,2],[1,2]);
# my $valid3 = Game::Term::Map->new( from => \@validAoA );
# ok ( ref $valid3->{data} eq 'ARRAY', "data part of the object is an array (valid array reference)"); 
# ok ( ref $valid3->{data}[0] eq 'ARRAY', "AoA (valid array reference)"); 

# my $valid1 = Game::Term::Map->new( fake_map => 'SMALL' );
# ok ( ref $valid1->{data} eq 'ARRAY', "data part of the object is an array (valid fake_map)"); 
# ok ( ref $valid1->{data}[0] eq 'ARRAY', "AoA (valid fake_map)");
# ok ( $valid1->{data}[0][0] eq '#', "expected first tile (valid fake_map)");
# ok ( $valid1->{data}[0][9] eq '#', "expected last, (default sized) tile (valid fake_map)");
# ok ( $valid1->{data}[9][0] eq $valid1->{data}[9][9], 
			# "expected (default sized) last row tiles (valid fake_map)");

# # if ( $ENV{TEST_VERBOSE }){
	# # note"map received:";
	# # foreach my $row(@{$valid1->{data}}){
		# # print +(join '', @$row),$/;
	# # }
# # }

# my $valid4 = Game::Term::Map->new( fake_map => 'SMALL', fake_y => 20, fake_x => 20 );
# ok ( $valid4->{data}[19][0] eq $valid4->{data}[19][19], 
			# "expected (custom sized) last row tiles (valid fake_map)");


# my $tempfile = File::Spec->catfile( File::Spec->tmpdir(),
									# 'map-'.int(rand(1000)).int(rand(1000)).'.txt');
# open my $fh, '>', $tempfile or BAIL_OUT "unble to open [$tempfile] for writing!";
# foreach my $row(@{$valid4->{data}}){
		# print $fh +(join '', @$row),$/;
# }
# close $fh;
# note "created [$tempfile]\n";

# my $valid5 = Game::Term::Map->new( from => $tempfile );
# ok ( $valid5->{data}[19][0] eq $valid5->{data}[19][19], "valid map from file: $tempfile");
# ok (!$valid5->{data}[20][0],"not too much rows" );
# ok (!$valid5->{data}[0][20],"not too much columns" );

# open my $fh, '>>', $tempfile or BAIL_OUT "unble to open [$tempfile] for appending!";
# print $fh "aaa\naa\na\naaaa\n";
# close $fh;
# dies_ok { Game::Term::Map->new( from => $tempfile ) } 
		# "expecting to die with not rectangular map file";
# unlink $tempfile;
# note "removed [$tempfile]\n";

# dies_ok { Game::Term::Map->new( from => 'Should_Not_Exist.txt' ) } 
		# "expecting to die with not existing file";

__DATA__
__DATA__
WWWWWWwwwwwwwwWWWWWW
     tttt           
 ttt    tTT t       
    tt    tT        
wwwwwwwwww          
  ttt           mM  
    wW              
              ww    
             wWwW   
tTtTtTtTt           
S                  S

