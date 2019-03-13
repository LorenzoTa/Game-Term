package Game::Term::UI;

use 5.014;
use strict;
use warnings;
use Term::ReadKey;

ReadMode 'cbreak';

our $VERSION = '0.01';

my $debug = 0;

sub new{
	my $class = shift;
	my %conf = _validate_conf( @_ );
	
	
	return bless {
				%conf
	}, $class;
}


sub run{
		my $ui = shift;
		$ui->_set_map_and_hero();
		print "DEBUG: REF ui->map: ",ref $ui->{map},"\n",
				"DEBUG: REF ui->map[0]: ",ref $ui->{map}->[0],' = ',@{$ui->{map}->[0]},"\n",
				"DEBUG: NEW map hero at: $ui->{hero_pos}->[0] $ui->{hero_pos}[1]\n"
				if $debug;
	
		$ui->_draw_map();
		$ui->_draw_menu();	
		while(1){
			my $key = ReadKey(0);
			
			if( $ui->move( $key, $ui->{hero_pos}) ){
			
				$ui->_draw_map();
				$ui->_draw_menu( ["key $key was pressed:",] );
			

			}
			
			print "DEBUG: map: rows 0 - $#{$ui->{map}} columns 0 - $#{$ui->{ map }[0]}\n"
					if $debug;
			print 	"DEBUG: map extended:\n",
					map{ join'',@$_,$/ } @{$ui->{map}}
						if $debug > 1;
		
		
		
		}
}
sub move{
	my $ui = shift;
	my $key = shift;
    # move with WASD
    if ( $key eq 'w' and  is_walkable($ui->{map}->	[
														$ui->{hero_pos}[0] - 1
													]
													[
														$ui->{hero_pos}[1]
													]
							)
		){
        print "free move up!\n";
        #$off_y-- if $scroll;
        # $map[ $$pos[0] ][ $$pos[1] ] = ' ';
		$ui->{map}->[$ui->{hero_pos}[0]][$ui->{hero_pos}[1]] = ' ';
        # $$pos[0]--;
		$ui->{hero_pos}[0]--;
        return 1;
    }
}

sub is_walkable{
	my $tile = shift;
	if( $tile eq ' ' ){ return 1 }
	else{return 0}
}
		
sub _draw_menu{
	my $ui = shift;
	my $messages = shift;
	# MENU AREA:
	# print decoration first row
	print ' o',$ui->{ dec_hor } x ($ui-> { map_area_w }), 'o',"\n";
	# menu fake data
	print ' ',$ui->{ dec_ver }.$_."\n" for @$messages;
}
sub _draw_map{
	my $ui = shift;
	# clear screen
	system $ui->{ cls_cmd } unless $debug;
	$ui->{map}[ $ui->{hero_pos}->[0] ][ $ui->{hero_pos}->[1] ] = 'X';
	# calculate offsets (same calculation is made in _set_map_and_hero)
	my $off_x = int( $ui->{ map_area_w } / 2 ) + 1;
	my $off_y = int( $ui->{ map_area_h } / 2 ) + 1;
	# MAP AREA:
	# print decoration first row
	print ' o',$ui->{ dec_hor } x ( $ui->{ map_area_w } ), 'o',"\n";
	# print map body with decorations		
	foreach my $row ( @{$ui->{map}}[ $off_y..$#{$ui->{map}}-$off_y] ){ # era $#map 
		print 	' ',$ui->{ dec_ver },
				@$row[ $off_x..$#$row-$off_x ],
				$ui->{ dec_ver },"\n"
	}
	# print decoration last row
	print ' o',$ui->{ dec_hor } x ($ui-> { map_area_w }), 'o',"\n";
}


sub _set_map_and_hero{
	my $ui = shift;
	unless (defined $ui->{ map }[0][0] ){
			$ui->{map} =[ map{ [(' ') x ($ui->{ map_area_w })] } 0..$ui->{ map_area_h }-1];
			$ui->{map}[0][0] = '#';
			$ui->{map}[0][-1] = '#';
			$ui->{map}[-1][0] = '#';
			$ui->{map}[-1][-1] = '#';
			# fake hero
			$ui->{map}[-1][10] = 'X';
		}
		# get hero position and side BEFORE enlarging
		my ($pos,$starting_side) = $ui->_get_hero_pos();
		print "DEBUG: hero at $$pos[0]-$$pos[1] (in original map) side: $starting_side\n" if $debug;
		
		
		# add empty spaces for a half in four directions
		# same calculation is made in run for offsets
		my $half_w = int( $ui->{ map_area_w } / 2 ) + 1;
		my $half_h = int( $ui->{ map_area_h } / 2 ) + 1;
		#
		print "DEBUG: half: w: $half_w h: $half_h\n"
				if $debug > 1;
		# add at top
		my @map = map { [ ($ui->{ ext_tile }) x ($half_w+$ui->{ map_area_w }+$half_w) ]} 0..$ui->{ map_area_h}/2 ; 
		# at the center
		foreach my $orig_map_row( @{$ui->{map}} ){
			push @map,	[ 
							($ui->{ ext_tile }) x $half_w,
							@$orig_map_row,
							($ui->{ ext_tile }) x $half_w
						]
		}
		# add at bottom
		push @map,map { [ ($ui->{ ext_tile }) x ($half_w+$ui->{ map_area_w }+$half_w) ]} 0..$ui->{ map_area_h}/2 ;
		
		@{$ui->{map}} = @map;
		$ui->{hero_pos} = [ 
							$$pos[0] + ( $ui->{ map_area_h}/2 + 1 ),
							$$pos[1] + ( $ui->{ map_area_w}/2 + 1 )	
						];
		$ui->{hero_side} = $starting_side;
	
}
sub _get_hero_pos{
	my $ui = shift;
	# hero position MUST be on a side and NEVER on a corner
	my $pos;
	my $side;
	foreach my $row ( 0..$#{$ui->{map}} ){
		foreach my $col ( 0..$#{$ui->{map}->[$row]} ){
			if ( ${$ui->{map}}[$row][$col] eq 'X' ){
				$pos = [ $row, $col];
				if    ( $row == 0 )						{ $side = 'N' }
				elsif ( $row == $#{$ui->{map}} )		{ $side = 'S' }
				elsif ( $col == 0 )						{ $side = 'W' }
				elsif ( $row == $#{$ui->{map}->[$row]} ){ $side = 'E' }
				else									{ die "Hero side not found!" }
				return $pos,$side;
			}				
		}
	}	
}

sub _validate_conf{
	my %conf = @_;
	$conf{ map_area_w } //= 20;
	$conf{ map_area_h } //= 10;
	$conf{ menu_area_w } //= $conf{ map_area_w };
	$conf{ menu_area_h } //= 20;
	$conf{ dec_hor }     //= '-';
	$conf{ dec_ver }     //= '|';
	$conf{ ext_tile }	//='O';
	$conf{ cls_cmd }     //= $^O eq 'MSWin32' ? 'cls' : 'clear';
	$conf{ map } //=[];
	$conf{ hero_pos } = [];
	$conf{ hero_side } = '';
	return %conf;
}

1; # End of Game::Term::UI
__DATA__
perl -I .\lib -MGame::Term::UI -MData::Dump -e "$ui=Game::Term::UI->new(); print $ui->{map_area_w}.$/;dd $ui; dd $ui->{map};$ui->run"
perl -I .\lib -MGame::Term::UI -MData::Dump -e "$ui=Game::Term::UI->new();$ui->run"

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


