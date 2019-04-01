package Game::Term::Map;

use 5.014;
use strict;
use warnings;



our $VERSION = '0.01';

sub new{
	my $class = shift;

	my %conf = validate_conf( @_ );

	# $conf{data} is here now..
	validate_data( $conf{data} );

	return bless {
				%conf
	}, $class;
}



sub validate_conf{
	my %conf = @_;
	# FROM param absent
	unless ( $conf{from} ){
	#die $conf{ fake_map };
		$conf{ fake_map } //= 'one' ;
		$conf{ fake_x } //= 40; #80;
		$conf{ fake_y } //= 20; #20;

		$conf{data} = fake_map( $conf{ fake_map },$conf{ fake_x },$conf{ fake_y } );
		map{ delete $conf{$_} }qw( fake_map fake_x fake_y );
		return %conf;
	}
	# FROM param present
	$conf{data} = [];
	if ( ref $conf{from} eq 'ARRAY' ){
		map{ die "not received an array of arrays!" unless ref $_ eq 'ARRAY' }@{$conf{from}};
		$conf{data} = $conf{from};
	}
	elsif( -e -f -s $conf{from} ){
		open my $fh, '<', $conf{from} or die "unable to open [$conf{from}] map file";
		while(<$fh>){
			chomp;
			push @{$conf{data}}, $_;
		}
	}
	elsif( fileno $conf{from} > 2){
	while(<$conf{from}>){
			chomp;
			push @{$conf{data}}, $_;
		}
	}
	else{ die "at the moment only a file or an AoA are supported as maps" }

	return %conf;
}

sub validate_data{
	my $aoa = shift;
	my $same_len = undef;
	my $c_row = 0;
	foreach my $row ( @$aoa ){
		my @row = ($row=~/./g);#split '',$row;
		#print +(join '',@$row)," el: $#{$row}\n"; next;
		if ( defined $same_len and $same_len != $#{$row} ){
			die "map data:\n[",(join '',@$row),"]\nat row $c_row is of different lenght ( ",$#{$row}," comparing with $same_len)";
		}
		else{ $same_len = $#{$row};}
		$c_row++;
	}
}


sub fake_map{
	my ($type, $x, $y) = @_; 
	my $map = [];
	if ($type =~ /^S$/i){ # hero at S
		$map = [ map{ [(' ') x $x  ] } 0..$y   ];
				$$map[0][0] 	= '#';
				$$map[0][-1] 	= '#';
				$$map[-1][0] 	= '#';
				$$map[-1][-1] 	= '#';
				# fake hero
				$$map[-1][ int($x/2) ] 	= 'X' ;#'X';
	}
	elsif ($type =~ /^N$/i){ # hero at N
		$map = [ map{ [(' ') x $x  ] } 0..$y   ];
				$$map[0][0] 	= '#';
				$$map[0][-1] 	= '#';
				$$map[-1][0] 	= '#';
				$$map[-1][-1] 	= '#';
				# fake hero
				$$map[0][ int($x/2) ] 	=  'X' ;#'X';
	}
	elsif ($type =~ /^E$/i){ # hero at E
		$map = [ map{ [(' ') x $x  ] } 0..$y   ];
				$$map[0][0] 	= '#';
				$$map[0][-1] 	= '#';
				$$map[-1][0] 	= '#';
				$$map[-1][-1] 	= '#';
				# fake hero
				$$map[ int($y/2) ][-1] 	=  'X' ;#'X';
	}
	elsif ($type =~ /^W$/i){ # hero at w
		$map = [ map{ [(' ') x $x  ] } 0..$y   ];
				$$map[0][0] 	= '#';
				$$map[0][-1] 	= '#';
				$$map[-1][0] 	= '#';
				$$map[-1][-1] 	= '#';
				# fake hero
				$$map[ int($y/2) ][0] 	=  'X' ;#'X';
	}
	elsif ($type =~ /^one$/i){
		my $fake=<<EOM;
tttt ttTTTTTTTTTTTTTTTTTTTTTTTTTTmmmMMWWwwMMttt ttmMMMMmmmmmmmmMtMMMMM hhhhhMMMM
ttttt ttttTTTTTTTTTTTTTTTTTTTTTTTmmmmmWWMwmttttttmMMMmtttthhmmmMMmmmmmttt  httmm
ttttttTTTTTttttttTTTTTttttttttttt  bbWWwwmmttttttmMM ht MttthhmMMmmm tt hhhhMMmm
 ttttTTtttttttttttttttttttttttttt WWbbwtwmmttttttmMhhh  MMMthhmMMmmthhhhh tMtmmt
 tttTTttt                   ttttWWWwwbbwtmmtttttt M hh   MMtttt tmm hhtth MMmmMt
   tttt     tttttttt           WWwwwwwbbtttttttt  MMMMmm      tttMmhh tth Mmm tt
   Tt     tttttttttt          WWwwhhhhh    tttt   MMMMMm         Mthhtt Mmmm mtt
   ttt  ttwwwwwtt     ttttttAAAAAhhhhh     tttt       Mmmm      MMt  t Mmmtmmm t
  tt   ttwwwwwwww   ttttttt AAAAAhhmMMM     ttt          m   MMmmhhh   Mm t t  t
  t   tttwwWWWWww  ttttttt   WWwhhhmMMMM    ttt        mmm   Mmhhhmh MMMm t   tt
     ttttwwBBWWww  tt tt     WWwwhhhMM                mmMMMMMhhhtmhh     tttt tt
     ttttwBBWWWww  t  t       Wwwwhh             ttt   MMhhhhhttttmtmm  tttttttt
     ttttBBwWWWww  t  hmmmh   WWwwww     tttttttttttt  MMhttttttttmmmm  tttttttt
     tttBBwwwwww   tt hhhmh    WWwwww   tttttttTTtttt                m   ttttt t
     ttttttwwwwtttttthhhhhh      WWww   ttttttttTTTTttttTttt       ttmmm   ttttt
      ttt tttttt tt t            WWwww    tttttttttTTtttTTTttt     tttTt      tt
             tt tt      WWWWWWaaWWwwww      tttttttttttttttTTtt    tttTttt      
          hhhh  t   WWWWWWwwwwaawwwwww      tt           tttTtt     ttTTTt     t
         mmhhhhtt WWWwwwwwwsssaa wwwww                      ttttt     ttTTtttttt
      h mm ht  tssWWwwssssssss    sss                       ttttt      tTtttttTt
     hhmmhttttttswWwssssssss       ss      tttt                 tttt      tttTtt
     hhhhhttttttswWwsSSssSSs           ttttttt   ttttt       tttt           tTTT
         ttttt sswwwssSSSSSs           tttttt    ttttt        tTt       ttttttTT
        tttttsssswwWwsSSSSSSss        ttttttt    ttttt      tttTt      ttttttTTt
        tt   sssswWwwsssSSSSSs       tthhttt    tttt       ttTTTt      tttTTTTTt
       ttt ssssswWwwwssssSSsss   ttttthhhht    sssss       tTTttt      tttttttTt
           ssssswWwwwwsssssss    tthhhhhht     ssSSss      tTTt             ttTT
           sswwwwWWWwwwsssssss    hhhhhhtt     ssSSSss                      tttT
          sswwWWWWWWWwwwssssss      ttttt  yyt tsssssss                ttt  tttT
         sswwWWWWWWWWWWWwwwssss          yyyytttt  ttt           tt   tttt  ttTT
 t      sswwWWWWWWWWWWWWWWWWwws          TTTTTTTttt    ttt ttttttttttttttt  ttTt
ttt    ssswWWWWWWWWWWWWWWWWWWwww         TTTTTTTTTttt tt ttttTTTTtttttttttttTTTt
ttt  ssssswWWWWWWWWWWWWWWWWWWWWWw    X  TTTTTTTTTTTtt tTTTTTTTttTTTTTTtttttttttt
EOM
		foreach my $row( split "\n", $fake){
			push @$map,[ split '', $row ]
		}
	}
	elsif ($type =~ /^render$/i){
		my $fake=<<EOM;
#                  #
     tttt  T
 ttt    tTT t
    tt    tT
tttttttttttttttt
  ttt   tt      nN
    wW
         mM   ww
             wWwW

#        X         #
EOM
	foreach my $row( split "\n", $fake){
			push @$map,[ split '', $row ]
		}
	}
	elsif ($type =~ /^two$/i){
		my $fake=<<EOM;
wwwWWWWWWwwwwww
  wWWWWWWwwww
  wWWWWwww
   wwwww    tt     tt
   wwww     tttt  tt tt
              tt TTT tt
  mm M       t  TTTTTt
   mmM       tttTTTTTtt
    mMMM        TTTTT
  m m MM       tTTTTt
  m mMM        t  ttt
  m  MMMMM     ttttt
  mm mmmM          ttt
       m            t
      mm            t
      m             t
      mm
       m
        m   X
EOM
	foreach my $row( split "\n", $fake){
			push @$map,[ split '', $row ]
		}
	}

    else{die}
	return $map;

}

1; # End of Game::Term::Map

__DATA__
=head1 NAME

Game::Term::Map - The great new Game::Term::Map!

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Game::Term::Map;

    my $foo = Game::Term::Map->new();
    ...


=head1 METHODS

=head2 new


=head1 AUTHOR

LorenzoTa, C<< <lorenzo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game::term at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game::Term>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Term::Map


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

