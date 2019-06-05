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
	
    use Game::Term::Configuration;
    use Game::Term::Game;
    use Game::Term::Scenario;
    use Game::Term::Actor;
    use Game::Term::Actor::Hero;

    # bare minimum scenario.. 
    my $scenario = Game::Term::Scenario->new(
        name => 'Test Scenario 1',
        actors => [
                        Game::Term::Actor->new( name => 'ONE', y => 5, x => 5 ),
                        Game::Term::Actor->new( name => 'TWO', y => 5, x => 7, energy_gain => 2 ),					
                     ]
    );
	
    # ..with map in DATA of the current file
    $scenario->get_map_from_DATA();
	
    # set the hero at given position or to a defualt location
    $scenario->set_hero_position( @ARGV ? @ARGV : 'south11' );

    # a basic configuration will use 16 colors
    # use Game::Term::Configuration->new( colors_map => 256 )
    # if your console supports them
    my $conf = Game::Term::Configuration->new();
	
    # hero has to be qualified in the first scenario
    my $hero = Game::Term::Actor::Hero->new( name => 'My New Hero' );

    # the game object feed with all the above
    my $game = Game::Term::Game->new( 
                                      debug         => 0,  
                                      configuration => $conf, 
                                      scenario      => $scenario,
                                      hero          => $hero,

    );

    # start the game loop
    $game->play();

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
    M                 mm

=head1 DESCRIPTION

Game::Term aims to be a fully usable game engine to produce console games, ie ASCII art games to be run in the Linux console or Windows cmd.exe command prompt. Colors are provided using ansi escape sequences. 
The engine is at the moment usable but still not complete and only few things are implemented.


=head2 configuration

The configuration of the game engine, handled by the L<Game::Term::Configuration> module, stores two kind of informations.
The first group is C<interface> and is about the appearence and default directories and files.

The second group is C<terrains> and holds various infos about every possible terrain based on how many colors the engine will use (2, 16 or 256 as specified in the C<interface> section).

Once generated the configuration is saved into the C<GameTermConfDefault.conf> under the game directory and will be loaded from this file preferentially.

The engine lets you to reload the configuration during the game: so if you dont like the default hero's icon or color you can change them in the configuration file created after the game start and reload the configuration (see the appropriate command below) to have them applied.



=head2 maps

The map is rendered on the console screen as a scrollable rectangle of ASCII characters.
It is displayed inside a box with the title of the current scenario at the top and a user's menu at the bottom.

Basically a redraw of the screen is accomplished clearing the buffer with the system call appropriate for the OS in use.

The map is handled by L<Game::Term::Map> module.

A valid map is an Array of Arrays each one of the same length containing empty spaces or other characters for various terrains.
A map can be contained in a separate file or inside the scenario program under the C<__DATA__> token.

The render engine will transform the map before drawing it to the screen adding colors and other attributes to each tile.

Each tile of the map inside the UI will hold an anonymous array with 3 elements:

=over

=item

[0] - the colored character to display ( for the same terrain type one or more characters and colors can be used )

=item

[1] - the original character ( used as terrain identifier )

=item

[2] - 0 if the tile is masked and 1 if it is already discovered (unmasked) and has to be displayed.

=back

The map only contains terrain informations, no actors nor the hero.

A MapEditor using L<Tk> is included in the distribution.


=head2 UI

The User Interface is governed by the L<Game::Term::UI> module. It loads and applies a configuration, draws pixels on the console screen and grabs user's input.

UI will create a frame where a scrolllable map is displayed. Scroll is ruled by hero's position.

All fancy color effects provided by L<Term::ANSIColor> are applied in the UI (Windows user might need to load and run C<ansicon.exe> from L<https://github.com/adoxa/ansicon> to have ansi sequences correctly interpreted). 

Generally the UI will mask parts of the map not yet explored and will put "fog of war" in empty spaces ( plains ) outside hero's sight.

Even if the map is all discovered only creatures in the hero's sight are displayed and their moves will trigger a refresh of the map.

=head2 scenarios

The scenario concept cover two distinct things. Firstly a C<scenario> is a regular Perl program as shown in the synopis: a C<.pl> program that uses the current suit of modules, mainly building up a L<Game::Term::Game> object, to start a new game by calling C<$game-E<gt>play()> 

To make this funnier the above perl program will inject into the game object a scenario constitued by a map, some creature lurking on the map and possibly events and more.

The scenario is created and handled using the L<Game::Term::Scenario> module and its few methods.

If an argument is passed to the program setting up the scenario this will be used as hero's starting position. This argument is passed in like: C<south5> meaning on the south side of the map at tile 5 (starting from 0) or C<west22> or similar. An alternative way of passing hero's starting position is formed by three arguments (the string C<middle> and C<y> and C<x> coordinates) like: C<middle 19 72> to intend hero enters at row 19 column 72.

The scenario will also sets all default intial values for: the hero position, number and kind of present actors and every other entities a scenario can hold.


=head2 game state and user's saves

The game object created using L<Game::Term::Game> will take track of the game state in a file (normally C<GameState.sto> stored in the main game diretory as stated in the configuration). This file will hold the hero's state and the information about progress achieved in each scenario.

If the hero come back to an already visited scenario, parts of the map already explored will be visible e and actors already defeated (or enigmas already resolved) will be not present.

This beahviour and the above descripted scenario ability (to receive as argument the hero's starting position), make a scenario reusable during game different phases.

Eaxample: hero explores part of C<scenario one> (which defaults are stored in C<scenario_one.pl> file) and exits the map entering into C<scenario two> (stored in C<scenario_two.pl>). When they come back to C<scenario one> not the defaults contained in C<scenario_one.pl> file are used but the data about C<scenario one> contained in the C<GameState.sto> file. This is valid for the map, actors and also for events (more on this in a while). So a perl program containing a scenario holds data used first time it is used: after data will be retrieved from theC<GameState.sto> file.    

By other hand user can save the game every moment: this action will save a precise snapshot of the game at the current time, in the current scenario. All objects stored in the save file (the game one using the scenario one, the configuration, the hero and all) can be saved and reloaded by the user at any moment. This does not affect the game state file that is modified only exiting a scenario.


=head2 game object

The game object created using L<Game::Term::Game> module rules them all. 

It holds the main game loop triggered by the C<$game-E<gt>play()> call. 

It needs to be feed with a scenario and a UI and (if not retrieved looking into the C<GameState.sto> file) with an hero. If present, scenario data will be modified according to C<GameState.sto> informations. The UI, if nothing is specified, will be loaded using values provided by C<GameTermConfDefault.conf> file.

The game object receives user's command from the UI, performs it's own operations and instruct the UI on how the screen has to be drawn.


=head2 hero and actors

Hero (impersoned by the user) and actors belong to the C<Game::Term::Actor> class. Hero in particular is an object of the derived class C<Game::Term::Actor::Hero>

The C<Game::Term::Actor> class defines few common attributes and has information used by the movement system. Each actor in the game loop receives an amount of energy as specified by its C<energy_gain> properties. When energy reaches a given treshold the actor can move.

This will results in actors moving at different speed while in reality they just receive less or more moves in respect to the hero.

Hero in addition has a sight that modifies the area of the map currently without the "fog of war" and the amplitude of the explored map. This sight range will be shorter while the hero is inside a wood and greater when hero is on elevated places like hills or mountains.

Walking on different kinds of terrain will result in faster or slower mevements of the hero, simulated timing the speed used to refresh the screen. 
 

 
=head2 commands

User's commands can be of two distinct kinds: map commands are essentially movements (and few others that also consume a move like using object, or that not count as movement like inspecting the bag) and are issued by the user with the C<wasd> keys. Each keypress will be a separate command. The C<h> command prints a short description of all commands.

Pressing the C<:> key the user enters in C<command mode> where commands available are issued as longer strings possibly with more terms (like in C<save my_first_save.sav> or C<configuration ./MyCustomConf.yaml>). Hitting C<TAB> will expand command names. The command C<return_to_game> is used to return back to the C<map mode>.

Generally every command issued while in C<map mode> will result in a screen redraw but the same is not true for commands issued while in C<command mode> where a pseudo prompt is present.
 
Currently commands are (as shown by the inline help):

      MAP MODE (exploration)

      w   walk north
      a   walk west
      s   walk south
      d   walk east

      b   show bag content
      u   use an item in the bag (counts as a move)

      h   show this help

      l   show labels on the map

      m   show message history

      :   switch to COMMAND MODE



      COMMAND MODE (use TAB to autocomplete commands)

      save [filename]
              save (using YAML) the current game into filename
              or inside a filename crafted on the fly

      load filename
              reload the game from a specified save

      configuration [filename]
              reload the UI configuration from a YAML file if specified
              or from the default one

      show_legenda
              show the legenda of the map (to be implemented)

      return_to_game
              bring you back to MAP MODE




=head2 events and timeline

Events are the salt and spices of a sceanrio. They are created from the L<Game::Term::Event> class. They can specify different things happening at some time or under certain conditions. For the moment is important to know how they happen and how they modify the game.

Events are created in the scenario (perl program) and passed to the game object in the C<events =E<gt> [...]> parameter.

Events not triggered at a given turn are left in the game oject and are checked every game turn to see if they have to be rendered (hero at given tile, doors to other scenarios and alike).

Time events are treated differently: once the game object receives them, it builds up a B<timeline> structure, a queue of game turns containing one, zero or more events each turn.

This  B<timeline> will be an array of array, like (* on current turn):

 [
  * undef,              # turn 0 no events
    [ event1 ],         # turn 1 will trigger event1
    undef,              # turn 2 no events
    [ event2, event3 ]  # turn will trigger event2 and then event3
 ]

Once time events are pushed into the B<timeline> they are removed from the game main events list.

When turn 1 will happen ( turns are count based on hero's perspective ) the game object will check its own list of event and events contained in the B<timeline> at the given position. In the above example C<event1> is scheduled to run at turn 1 and it is rendered.

If C<event1> has a C<duration> specified another event is spawned automatically, let's say C<event1-end>, to mark the end of C<event1>.

Let's continue the above example saying that C<event1> will increase hero's sight for 3 turns, the following will happen during the event rendering:

 [
    undef,              # turn 0 no events
   *[ event1 ],         # turn 1 will trigger event1
    undef,              # turn 2 no events
    [ event2, event3 ]  # turn 3 will trigger event2 and then event3
    [ event1-end ]      # created automatically by event1
 ]

Time events and events marked to run only once are then removed from any queue. So at the turn 2 the B<timeline> will be:

 [
    undef,              # turn 0 no events
    [ undef ],          # turn 1 event already rendered is removed
   *undef,              # turn 2 no events
    [ event2, event3 ]  # turn will trigger event2 and then event3
    [ event1-end ]      # created automatically by event1
 ]

In the current implementation all events must have a valid C<target> or they will be removed from the queue.

To exit from the current scenario entering into another one, basically, does not delete this timeline but will import scheduled timeline events into the timeline of the new scenario. So an effect during 10 turns can be in effect 3 turns in a scenario and 7 turns in the next one (this is valid only for the hero: effects on other actors will end exiting the current scenario).

Events not in the timeline (doors or other events triggered at particular locations) are saved in the C<GameState.sto> file section dedicated to current scenario on exit. These saved events will overwrite events defined in the scenario file when hero will enter it again.



=head2 debug levels

Debug can be set to C<0> that means that the game is intended to be played and the screen is refreshed as needed (buffer is cleared) or to C<1> to display game informations and the screen is not cleared or to C<2> dumping a lot of used datastructures used during the game as raw and beautified maps, status of the hero's object and more.

The debug level is passed during the construction of the game object C<debug =E<gt> 1> or C<debug =E<gt> 2>

To mantain the game developer sane if debug is set the game state is also saved into a specular YAML file named C<GameState.sto.yaml>


=head2 labels and names

The UI has the ability momentary show labels defined in the scenario (place names) and names of creatures lurking in the map if in the sight range. Labels are not saved in the C<GameState.sto> file but are loaded from the scenario file.

Place labels are assigned in the sceario to a tile and if this tile is discovered then the labels can be shown and will be shown also if covered by the fogo of war effect.

=head1 AUTHOR

LorenzoTa, C<< <lorenzo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game::term at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game::Term>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT


The main support site for this module is  L<perlmonks.org|http://perlmonks.org/>

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

Jason Hood for his precious work:  L<ansicon|https://github.com/adoxa/ansicon>

The whole L<perlmonks.org|https://perlmonks.org> community for continous support and specially Corion, choroba, marto
tybalt89 (the illumunate method is mainly his work), Tux, Marshall, hippo, Eily..

Folks on perl irc channel and especially mst and integral for some nice trick they show me.

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
