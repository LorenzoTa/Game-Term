package Game::Term::UI;

use 5.014;
use strict;
use warnings;
use Term::ReadKey;

use Game::Term::Map;

ReadMode 'cbreak';

our $VERSION = '0.01';
#my $fake_map = 1;
my $debug = 0;
my $noscroll_debug = 1;

sub new{
	my $class = shift;
	my %conf = validate_conf( @_ );
	
	
	return bless {
				%conf
	}, $class;
}


sub run{
		my $ui = shift;
		
		my $map = Game::Term::Map->new(  );
		print map{ join'',@$_,$/ } @{$map->{data}} if $debug > 1;
		$ui->{map} = $map->{data};
		
		$ui->set_map_and_hero();
		# now BIG map, hero_pos and hero_side are initialized
		# time to generate offsets for print: map_off_x and map_off_y (and the no_scroll region..)		
		
		print "DEBUG: NEW MAP: rows 0 - $#{$ui->{map}} columns 0 - $#{$ui->{ map }[0]}\n" if $debug;
			
		$ui->set_map_offsets();
	
		$ui->draw_map();
		$ui->draw_menu( ["hero HP: 42","walk with WASD"] );	
		while(1){
			my $key = ReadKey(0);
			
			if( $ui->move( $key ) ){
				
				$ui->draw_map();
				
	if ($noscroll_debug){
		 $ui->{map}->[$ui->{no_scroll_area}{min_y}][$ui->{no_scroll_area}{min_x}] = '.';
		 $ui->{map}->[$ui->{no_scroll_area}{max_y}][$ui->{no_scroll_area}{max_x}] = '.';
		 #print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n";
		 print 	"MAP SIZE: rows: 0..",$#{$ui->{map}}," cols: 0..",$#{$ui->{map}->[0]}," \n",
				"NOSCROLL corners: $ui->{no_scroll_area}{min_y}-$ui->{no_scroll_area}{min_x} ",
				"$ui->{no_scroll_area}{max_y}-$ui->{no_scroll_area}{max_x}\n";
		 print "OFF_Y used in print: $ui->{map_off_y} .. $ui->{map_off_y} + $ui->{map_area_h}\n";
		 print "OFF_X used in print: ($ui->{map_off_x} + 1) .. ($ui->{map_off_x} + $ui->{map_area_w})\n";
	}
			
			
				$ui->draw_menu( ["hero HP: 42",
									"hero at: $ui->{hero_y}-$ui->{hero_x}",
									"key $key was pressed:"] );	

			}
			
			print "DEBUG: hero_x => $ui->{hero_x} hero_y $ui->{hero_y}\n" if $debug;		
		
		}
}

sub set_map_offsets{
	my $ui = shift;
	
	
	if ( $ui->{hero_side} eq 'S' ){
		
		$ui->{map_off_x} =   $ui->{hero_x} - 1 - $ui->{map_area_w} / 2;
		$ui->{map_off_y} =   $ui->{hero_y} - $ui->{map_area_h};
		
		print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n" if $debug;
	}
	elsif ( $ui->{hero_side} eq 'N' ){
		
		$ui->{map_off_x} =   $ui->{hero_x} - 1 - $ui->{map_area_w} / 2;
		$ui->{map_off_y} =   $ui->{hero_y}   ;# ????????????????
		
		print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n" if $debug;
	}
	elsif ( $ui->{hero_side} eq 'E' ){		
		$ui->{map_off_x} = $ui->{hero_x} - $ui->{map_area_w} ;
		#$ui->{map_off_y} = $ui->{hero_y} - 1 - 4 - $ui->{map_area_y} / 2; # ????????????????
													########?????????????????
		$ui->{map_off_y} = $ui->{map_area_y}  / 2 + ($ui->{hero_y} / 2  + 1); # ????????????????
		
		print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n" if $debug;
	}
	
	elsif ( $ui->{hero_side} eq 'W' ){		
		$ui->{map_off_x} = $ui->{hero_x} - 1 ; ###############NOOOOOOOOOOOOOO
		#$ui->{map_off_y} = $ui->{hero_y} - 1 - 4 - $ui->{map_area_y} / 2; # ????????????????
													########?????????????????
		$ui->{map_off_y} = $ui->{map_area_y}  / 2 + ($ui->{hero_y} / 2  + 1); # ????????????????
		
		print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n" if $debug;
	}
	else{die}

}
sub draw_map{
	my $ui = shift;
	# clear screen
	system $ui->{ cls_cmd } unless $debug;	
	# draw hero
	# this must set $hero->{on_terrain}
	$ui->{map}[ $ui->{hero_y} ][ $ui->{hero_x} ] = $ui->{hero_icon}; 
	# calculate offsets (same calculation is made in set_map_and_hero)
	my $off_x = int( $ui->{ map_area_w } / 2 ) + 1;
	my $off_y = int( $ui->{ map_area_h } / 2 ) + 1;
	# MAP AREA:
	# print decoration first row
	print ' o',$ui->{ dec_hor } x ( $ui->{ map_area_w } ), 'o',"\n";
	# print map body with decorations
	foreach my $row ( @{$ui->{map}}[  $ui->{map_off_y}..$ui->{map_off_y} + $ui->{map_area_h}  ] ){ 	
		# {local $@;
		# eval {
		no warnings qw(uninitialized);
				print 	' ',$ui->{ dec_ver },
				@$row[ $ui->{map_off_x} + 1 ..$ui->{map_off_x} + $ui->{map_area_w} ],
				$ui->{ dec_ver },"\n";
		# };
		# if ($@){
			# die "ERROR in draw map:\n",
					# #"ROW current  0 .. $#{$row}\n",
				# "OFF_X used in print: $ui->{map_off_x} + 1 .. $ui->{map_off_x} + $ui->{map_area_w}\n";
		# }
		# }#end of local $@
	}	
	# print decoration last row
	print ' o',$ui->{ dec_hor } x ($ui-> { map_area_w }), 'o',"\n";
}

sub move{
	my $ui = shift;
	my $key = shift;
	#check if leaving the no_scroll area
	
    # move with WASD
    if ( $key eq 'w' and  is_walkable(
							# map coord as hero X - 1, hero Y
							$ui->{map}->[ $ui->{hero_y} - 1 ][	$ui->{hero_x} ]
							)
		){
        #									THIS must be set to $hero->{on_terrain}
		$ui->{map}->[ $ui->{hero_y} ][ $ui->{hero_x} ] = ' ';
		$ui->{hero_y}--;
		$ui->{map_off_y}-- if $ui->must_scroll();
        return 1;
    }
	elsif ( $key eq 's' and  is_walkable(
							# map coord as hero X + 1, hero Y
							$ui->{map}->[ $ui->{hero_y} + 1 ][	$ui->{hero_x} ]
							)
		){
        #									THIS must be set to $hero->{on_terrain}
		$ui->{map}->[ $ui->{hero_y} ][ $ui->{hero_x} ] = ' ';
		$ui->{hero_y}++;
		$ui->{map_off_y}++ if $ui->must_scroll();		
        return 1;
    }
	elsif ( $key eq 'a' and  is_walkable(
							# map coord as hero X, hero Y - 1
							$ui->{map}->[ $ui->{hero_y} ][	$ui->{hero_x} - 1 ]
							)
		){
        #									THIS must be set to $hero->{on_terrain}
		$ui->{map}->[ $ui->{hero_y} ][ $ui->{hero_x} ] = ' ';
		$ui->{hero_x}--;
		$ui->{map_off_x}-- if $ui->must_scroll();		
        return 1;
    }
	elsif ( $key eq 'd' and  is_walkable(
							# map coord as hero X, hero Y + 1
							$ui->{map}->[ $ui->{hero_y} ][	$ui->{hero_x} + 1 ]
							)
		){
        #									THIS must be set to $hero->{on_terrain}
		$ui->{map}->[ $ui->{hero_y} ][ $ui->{hero_x} ] = ' ';
		$ui->{hero_x}++;
		$ui->{map_off_x}++ if $ui->must_scroll();				
        return 1;
    }
	else{
		print "unused [$key] was pressed\n" if $debug;
		return 0;
	}
	
}

sub must_scroll{
	my $ui = shift;
	return 0 if $ui->{no_scroll};
	return 1 if $ui->{scrolling};
	if(	 
		$ui->{hero_y} < $ui->{no_scroll_area}{min_y} or
		$ui->{hero_y} > $ui->{no_scroll_area}{max_y} or
		$ui->{hero_x} < $ui->{no_scroll_area}{min_x} or
		$ui->{hero_x} > $ui->{no_scroll_area}{max_x} #and $ui->{scrolling} == 0
	
	){
		print "DEBUG: OUT of scrolling area\n" if $debug;
		$ui->{scrolling} = 1;
		return 1;
	}
	# elsif(	 
		# $ui->{hero_y} > $ui->{no_scroll_area}{min_y} or
		# $ui->{hero_y} < $ui->{no_scroll_area}{max_y} or
		# $ui->{hero_x} > $ui->{no_scroll_area}{min_x} or
		# $ui->{hero_x} < $ui->{no_scroll_area}{max_x} and $ui->{scrolling} == 1
	
	# ){
		# print "DEBUG: IN of scrolling area\n" if $debug;
		# $ui->{scrolling} = 0;
		# return 0;
	# }
	else { return 0 }

}

sub is_walkable{
	my $tile = shift;
	if( $tile eq ' ' ){ return 1 }
	elsif( $tile eq '.' ){ return 1 }
	else{return 0}
}
		
sub draw_menu{
	my $ui = shift;
	my $messages = shift;
	# MENU AREA:
	# print decoration first row
	print ' o',$ui->{ dec_hor } x ($ui-> { map_area_w }), 'o',"\n";
	# menu fake data
	print ' ',$ui->{ dec_ver }.$_."\n" for @$messages;
}



sub set_map_and_hero{
	my $ui = shift;

	my $original_map_w = $#{$ui->{map}->[0]} + 1;
	my $original_map_h = $#{$ui->{map}} + 1;
	print "DEBUG origial map was $original_map_w x $original_map_h\n" if $debug;
	# get hero position and side BEFORE enlarging
	$ui->get_hero_pos();
			
	# add empty spaces for a half in four directions
	# same calculation is made in draw_map for offsets
	my $half_w = int( $ui->{ map_area_w } / 2 ) + 1;
	my $half_h = int( $ui->{ map_area_h } / 2 ) + 1;

	print "DEBUG: half: w: $half_w h: $half_h\n" if $debug > 1;

	# add at top
	my @map = map { [ ($ui->{ ext_tile }) x ($half_w + $original_map_w + $half_w) ]} 0..$half_h-1 ; 
	# at the center
	foreach my $orig_map_row( @{$ui->{map}} ){
		push @map,	[ 
						($ui->{ ext_tile }) x $half_w,
						@$orig_map_row,
						($ui->{ ext_tile }) x $half_w
					]
	}
	# add at bottom
	push @map,map { [ ($ui->{ ext_tile }) x ($half_w + $original_map_w + $half_w) ]} 0..$half_h-1 ;

	@{$ui->{map}} = @map;
	$ui->{hero_x} += $half_w; 
	$ui->{hero_y} += $half_h; 

	$ui->set_no_scrolling_area( $half_w, $half_h );
	
	# if ($noscroll_debug){
		 # $ui->{map}->[$ui->{no_scroll_area}{min_y}][$ui->{no_scroll_area}{min_x}] = '.';
		 # $ui->{map}->[$ui->{no_scroll_area}{max_y}][$ui->{no_scroll_area}{max_x}] = '.';
	# }

}

sub set_no_scrolling_area{
	my $ui = shift;
	my ( $half_w, $half_h ) = @_;
	if ( $ui->{no_scroll} == 0 ){
		if ( $ui->{hero_side} eq 'S' ){  
			$ui->{no_scroll_area}{min_x} = $ui->{hero_x} - int($ui->{map_area_w} / 4);
			$ui->{no_scroll_area}{min_y} = $ui->{hero_y} - $half_h;
			
			$ui->{no_scroll_area}{max_y} = $ui->{hero_y};
			$ui->{no_scroll_area}{max_x} = $ui->{hero_x} + int($ui->{map_area_w} / 4);
			
		}
		elsif ( $ui->{hero_side} eq 'N' ){ 
			$ui->{no_scroll_area}{min_x} = $ui->{hero_x} - int($ui->{map_area_w} / 4);
			$ui->{no_scroll_area}{min_y} = $ui->{hero_y}; 
			
			$ui->{no_scroll_area}{max_x} = $ui->{hero_x} + int($ui->{map_area_w} / 4);
			$ui->{no_scroll_area}{max_y} = $ui->{hero_y} + $half_h;			
		}
		
		elsif ( $ui->{hero_side} eq 'E' ){
			$ui->{no_scroll_area}{min_x} = $ui->{hero_x} - $half_w;#
			$ui->{no_scroll_area}{min_y} = $ui->{hero_y} - int($ui->{map_area_h} / 4)  ;
			
			$ui->{no_scroll_area}{max_x} = $ui->{hero_x} ;
			$ui->{no_scroll_area}{max_y} = $ui->{hero_y} + int($ui->{map_area_h} / 4 );						
		}
		elsif ( $ui->{hero_side} eq 'W' ){
			$ui->{no_scroll_area}{min_x} = $ui->{hero_x} ;
			$ui->{no_scroll_area}{min_y} = $ui->{hero_y} - int($ui->{map_area_h} / 4);
			
			$ui->{no_scroll_area}{max_x} = $ui->{hero_x} +  $half_w;
			$ui->{no_scroll_area}{max_y} = $ui->{hero_y} + int($ui->{map_area_h} / 4);			
		}
		else{die}
	}
	print "DEBUG: no_scroll area from $ui->{no_scroll_area}{min_y}-$ui->{no_scroll_area}{min_x} ",
			"to $ui->{no_scroll_area}{max_y}-$ui->{no_scroll_area}{max_x}\n" if $debug;
	
	local $ui->{map}->[$ui->{no_scroll_area}{min_y}][$ui->{no_scroll_area}{min_x}] = '-';
	local $ui->{map}->[$ui->{no_scroll_area}{max_y}][$ui->{no_scroll_area}{max_x}] = '-';
	
	print 	"DEBUG: map extended with no_scroll vertexes:\n",map{ join'',@$_,$/ } @{$ui->{map}} if $debug > 1;
	
	# if ($noscroll_debug){
		 # $ui->{map}->[$ui->{no_scroll_area}{min_y}][$ui->{no_scroll_area}{min_x}] = '.';
		 # $ui->{map}->[$ui->{no_scroll_area}{max_y}][$ui->{no_scroll_area}{max_x}] = '.';
	# }
}

sub get_hero_pos{
	my $ui = shift;
	# hero position MUST be on a side and NEVER on a corner
	my $pos;
	my $side;
	print "DEBUG: original map size; rows: 0..",$#{$ui->{map}}," cols: 0..",$#{$ui->{map}->[0]}," \n" if $debug;
	foreach my $row ( 0..$#{$ui->{map}} ){
		foreach my $col ( 0..$#{$ui->{map}->[$row]} ){
			if ( ${$ui->{map}}[$row][$col] eq 'X' ){
				print "DEBUG: (original map) found hero at row $row col $col\n" if $debug;
				$ui->{hero_y} = $row;
				$ui->{hero_x} = $col;
				if    ( $row == 0 )						{ $ui->{hero_side} = 'N' }
				elsif ( $row == $#{$ui->{map}} )		{ $ui->{hero_side} = 'S' }
				elsif ( $col == 0 )						{ $ui->{hero_side} = 'W' }
				elsif ( $col == $#{$ui->{map}->[$row]} ){ $ui->{hero_side} = 'E' }
				else									{ die "Hero side not found!" }
			}				
		}
	}	
}

sub validate_conf{
	my %conf = @_;
	$conf{ map_area_w } //= 80;
	$conf{ map_area_h } //=  20;
	$conf{ menu_area_w } //= $conf{ map_area_w };
	$conf{ menu_area_h } //= 20;
	$conf{ dec_hor }     //= '-';
	$conf{ dec_ver }     //= '|';
	$conf{ ext_tile }	//= 'O'; # ok with chr(119) intersting chr(0) == null 176-178 219
	$conf{ cls_cmd }     //= $^O eq 'MSWin32' ? 'cls' : 'clear';
	$conf{ hero_x } = undef;
	$conf{ hero_y } = undef;
	$conf{ hero_side } = '';
	$conf{ hero_icon } = chr(2);#'X'; 30 1 2 
	$conf{ map } //=[];
	$conf{ map_off_x } = 0;
	$conf{ map_off_y } = 0;
	$conf{ scrolling } = 0;
	$conf{ no_scroll } = 0;
	$conf{ no_scroll_area} = { min_x=>'',max_x=>'',min_y=>'',max_y=>'' };
	
		
	return %conf;
}



1; # End of Game::Term::UI
__DATA__
perl -I .\lib -MGame::Term::UI -MData::Dump -e "$ui=Game::Term::UI->new(); print $ui->{map_area_w}.$/;dd $ui; dd $ui->{map};$ui->run"
perl -I .\lib -MGame::Term::UI -MData::Dump -e "$ui=Game::Term::UI->new();$ui->run"

perl -I .\lib -MGame::Term::UI -e "$ui=Game::Term::UI->new();$ui->run"

=head1 NAME

Game::Term::UI - The great new Game::Term::UI!

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Game::Term::UI;

    my $foo = Game::Term::UI->new();
    ...


=head1 METHODS

=head2 function1


=head1 AUTHOR

LorenzoTa, C<< <lorenzo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game::term at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game::Term>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

Main support site for the current module is L<https://www.perlmonks.org|perlmonks.org>

You can find documentation for this module with the perldoc command.

    perldoc Game::Term::UI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game::Term>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Game::Term>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Game::Term>

=item * Search CPAN

L<https://metacpan.org/release/Game::Term>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 LorenzoTa.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


