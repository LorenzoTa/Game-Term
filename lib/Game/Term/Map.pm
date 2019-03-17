package Game::Term::Map;

use 5.014;
use strict;
use warnings;



our $VERSION = '0.01';

sub new{
	my $class = shift;
	my %conf = validate_conf( @_ );	
	return bless {
				%conf
	}, $class;
}



sub validate_conf{
	my %conf = @_;
	$conf{ fake_map } //= 's' ;
	$conf{ fake_x } //= 30; #80;
	$conf{ fake_y } //= 20; #20;
	
	$conf{data} = fake_map( $conf{ fake_map },$conf{ fake_x },$conf{ fake_y } );
	return %conf;
}

sub fake_map{
	my ($type, $x, $y) = @_;
	my $map = [];
	if ($type =~ /^S/i){ # hero at S
		$map = [ map{ [(' ') x $x  ] } 0..$y   ];
				$$map[0][0] 	= '#';
				$$map[0][-1] 	= '#';
				$$map[-1][0] 	= '#';
				$$map[-1][-1] 	= '#';
				# fake hero
				$$map[-1][10] 	= 'X' ;#'X';
	}
	elsif ($type =~ /^N/i){ # hero at N
		$map = [ map{ [(' ') x $x  ] } 0..$y   ];
				$$map[0][0] 	= '#';
				$$map[0][-1] 	= '#';
				$$map[-1][0] 	= '#';
				$$map[-1][-1] 	= '#';
				# fake hero
				$$map[0][10] 	=  'X' ;#'X';
	}
	elsif ($type =~ /^E/i){ # hero at E
		$map = [ map{ [(' ') x $x  ] } 0..$y   ];
				$$map[0][0] 	= '#';
				$$map[0][-1] 	= '#';
				$$map[-1][0] 	= '#';
				$$map[-1][-1] 	= '#';
				# fake hero
				$$map[5][-1] 	=  'X' ;#'X';
	}
	elsif ($type =~ /^W/i){ # hero at w
		$map = [ map{ [(' ') x $x  ] } 0..$y   ];
				$$map[0][0] 	= '#';
				$$map[0][-1] 	= '#';
				$$map[-1][0] 	= '#';
				$$map[-1][-1] 	= '#';
				# fake hero
				$$map[5][0] 	=  'X' ;#'X';
	}
	elsif ($type =~ /^one/i){ 
		my $fake=<<EOM;
01234567890123456789012345678901234567890123      012345678901234567890123456789
##    #########################                     ########         ###########
##  #############################            ###    #########   ################
    ############################################    #########   ################
    #####                   ####################         ####   ########   #####
    ###     ########           ################         #####   ###       ######
          ##########                       ####         ####    ###      #######
        #########     ###############      ####   ###   ####    ###      ##### #
       ########     ###################     ###   ###   ###     ###      ####  #
      ######       #####################    ###   ###   ####             #### ##
     ######        #####          ######          ###   ############     #### ##
     ####          ####              ###         ####   ############     #######
     ####          ###                   ############    ###########      ######
     #####                              #############                     #### #
     #####                              ####################       ###     #####
      ####     #######                        ################     #####      ##
X             ########             #####      #################    #######      
   #          ########             ########              ######     ######     #
        #     ####                 #########               #####     ###########
    #         ###         ######     O######                #####      #########
         #    ###         #######       ####                 ####      #########
              ####        #######       ####     #####       ####           ####
   #  ###     ######      #######      ####      #####        ###       ########
      ###     ########                #####      #####      #####      #########
      ####      #########            ######     ####       ######      #########
      #####      #########################     #####       ######      #########
      #####        ######################      ######      ####             ####
       ####            #################       #######                      ####
       ####                                    #######                 ###  ####
       ############################                ###                 ###  ####
 #     ############################      ########                      ###  ####
###    012345678901234#############      ########         ######################
###                                                   ##########################
EOM
	#my @map;
	foreach my $row( split "\n", $fake){
		push @$map,[ split '', $row ]
	}
	#return @map;
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

