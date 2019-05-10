package Game::Term;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.01';

__DATA__

=head1 NAME

Game::Term - An ASCII game engine

=head1 VERSION

The present document describes Game::Term version 0.01



=head1 SYNOPSIS



    use strict;
    use warnings;
    use Game::Term::Game;

    use Game::Term::Scenario;
    use Game::Term::Actor;
    use Game::Term::Actor::Hero;

    # bare minimum scenario with map in DATA

    my $scenario = Game::Term::Scenario->new(
        name => 'Test Scenario 1',
        creatures => [
                        Game::Term::Actor->new( name => 'ONE', y => 5, x => 5 ),
                        Game::Term::Actor->new( name => 'TWO', y => 5, x => 7, energy_gain => 2 ),					
                     ]
    );
    $scenario->get_map_from_DATA();
    $scenario->set_hero_position( $ARGV[0] // 'south11' );


    my $conf = Game::Term::Configuration->new();
	
    my $hero = Game::Term::Actor::Hero->new( name => 'My New Hero' );

    my $game = Game::Term::Game->new( 
                                      debug         => 0,  
                                      configuration => $conf, 
                                      scenario      => $scenario,
                                      hero          => $hero,

    );


    $game->play()

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
    TTTTTTTTT           
    S                  S

=head1 DESCRIPTION

Game::Term aims to be a fully usable game engine to produce console games. 
The engine is at the moment usable but still not complete and only few things are implemented.


=head2 about configuration

The configuration of the game engine, handled by the L<Game::Term::Configuration> module, stores two kind of informations.
The first group is C<interface> and is about the appearence and default directories and files.

The second group is C<terrains> and holds various infos about every possible terrain based on how many colors the engine will use (2, 16 or 256 as specified in the C<interface> section).

Once generated the configuration is saved into the C<GameTermConfDefault.conf> under the game directory and will be loaded from this file.

The engine let you to reload the configuration during the game.



=head2 about maps

The map is rendered on the console screen as a scrollable quadrilater serie of ASCII characters.
It is displayed inside a box with the title of the current scenario at the top and a user's menu at the bottom.

Basically a redraw of the screen is accomplished clearing the buffer wih the system call appropriate for the OS in use.

The map is handled by L<Game::Term::Map> module.

A valid map is an Array of Arrays each one of the same length containing empty spaces or special characters for various terrains.
A map can be contained in a separate file or inside the scenario perl program under the C<__DATA__> token.

The render engine will transform the map before drawing it to the screen to add colors and other attributes to each tile.

Each tille will hold an anonymous array with 3 elements:

=over

=item

[0] - the colored character to display ( for the same terrain type one or more characters and colors can be used )

=item

[1] - the original character ( used as terrain identifier )

=item

[2] - 0 if the tile is masked 1 if it is already discovered (unmasked) and has to be displayed.

=back

The map only contains terrain informations, no the creatures nor the hero.






=head1 AUTHOR

LorenzoTa, C<< <lorenzo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game::term at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game::Term>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Term


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

1; # End of Game::Term
