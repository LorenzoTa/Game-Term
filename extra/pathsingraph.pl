use strict;
use warnings;
use Paths::Graph;
use Graph::Weighted;

use Data::Dump;
use Benchmark 'cmpthese';

my $max = $ARGV[0] || 4;
my $dest = $max.'_'.$max;

my @aoa = map{ 
				[ map{ int(rand(4))+1  }0..$max  ] 
	} 0..$max;
	

my %graph = build_graph();
dd %graph;
foreach my $row (0..$#aoa){
		foreach my $col( 0..$#{$aoa[$row]} ){
			print $aoa[$row][$col];
		}
		print "\n";
}


cmpthese( -2, {
    'Paths::Graph' => sub {
		my $obj = Paths::Graph->new(-origin=>"0_0",-destiny=>$dest,-graph=>\%graph);
		my @paths = $obj->shortest_path();
    },
    'Graph::Weighted' => sub {
		my $g = Graph::Weighted->new();
		$g->populate(\%graph);
		my @pathbis = $g->SP_Dijkstra( "0_0", $dest );
		dd @pathbis;
    },
    
});


sub build_graph{
	my %graph;
	foreach my $row (0..$#aoa){
		foreach my $col( 0..$#{$aoa[$row]} ){
			#print $row."_".$col." is current..\n";
			map{
			
				$graph{$row."_".$col}{$_->[0].'_'.$_->[1]} = $aoa[$_->[0]][$_->[1]]
					if 	$_->[0] >= 0 and
						$_->[0] <= $#{$aoa[$row]} and
						$_->[1] >= 0 and
						$_->[1] <= $#aoa 
			
			} ([$row-1,$col],[$row+1,$col],[$row,$col-1],[$row,$col+1]);
		}
	}

	return %graph;	
}