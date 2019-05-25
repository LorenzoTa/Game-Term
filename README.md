<html><head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1" >
</head>
<body class='pod'>
<!--
  generated by Pod::Simple::HTML v3.35,
  using Pod::Simple::PullParser v3.35,
  under Perl v5.024001 at Sat May 25 20:33:50 2019 GMT.

 If you want to change this HTML document, you probably shouldn't do that
   by changing it directly.  Instead, see about changing the calling options
   to Pod::Simple::HTML, and/or subclassing Pod::Simple::HTML,
   then reconverting this document from the Pod source.
   When in doubt, email the author of Pod::Simple::HTML for advice.
   See 'perldoc Pod::Simple::HTML' for more info.

-->

<!-- start doc -->
<a name='___top' class='dummyTopAnchor' ></a>

<div class='indexgroup'>
<ul   class='indexList indexList1'>
  <li class='indexItem indexItem1'><a href='#NAME'>NAME</a>
  <li class='indexItem indexItem1'><a href='#VERSION'>VERSION</a>
  <li class='indexItem indexItem1'><a href='#SYNOPSIS'>SYNOPSIS</a>
  <li class='indexItem indexItem1'><a href='#DESCRIPTION'>DESCRIPTION</a>
  <ul   class='indexList indexList2'>
    <li class='indexItem indexItem2'><a href='#configuration'>configuration</a>
    <li class='indexItem indexItem2'><a href='#maps'>maps</a>
    <li class='indexItem indexItem2'><a href='#UI'>UI</a>
    <li class='indexItem indexItem2'><a href='#scenarios'>scenarios</a>
    <li class='indexItem indexItem2'><a href='#game_state_and_user%27s_saves'>game state and user&#39;s saves</a>
    <li class='indexItem indexItem2'><a href='#game_object'>game object</a>
    <li class='indexItem indexItem2'><a href='#hero_and_actors'>hero and actors</a>
    <li class='indexItem indexItem2'><a href='#commands'>commands</a>
    <li class='indexItem indexItem2'><a href='#events_and_timeline'>events and timeline</a>
  </ul>
  <li class='indexItem indexItem1'><a href='#AUTHOR'>AUTHOR</a>
  <li class='indexItem indexItem1'><a href='#BUGS'>BUGS</a>
  <li class='indexItem indexItem1'><a href='#SUPPORT'>SUPPORT</a>
  <li class='indexItem indexItem1'><a href='#ACKNOWLEDGEMENTS'>ACKNOWLEDGEMENTS</a>
  <li class='indexItem indexItem1'><a href='#LICENSE_AND_COPYRIGHT'>LICENSE AND COPYRIGHT</a>
</ul>
</div>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="NAME"
>NAME</a></h1>

<p>Game::Term - An ASCII game engine</p>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="VERSION"
>VERSION</a></h1>

<p>The present document describes Game::Term version 0.01</p>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="SYNOPSIS"
>SYNOPSIS</a></h1>

<pre>    use strict;
    use warnings;
        
    use Game::Term::Configuration;
    use Game::Term::Game;
    use Game::Term::Scenario;
    use Game::Term::Actor;
    use Game::Term::Actor::Hero;

    # bare minimum scenario.. 
    my $scenario = Game::Term::Scenario-&#62;new(
        name =&#62; &#39;Test Scenario 1&#39;,
        actors =&#62; [
                        Game::Term::Actor-&#62;new( name =&#62; &#39;ONE&#39;, y =&#62; 5, x =&#62; 5 ),
                        Game::Term::Actor-&#62;new( name =&#62; &#39;TWO&#39;, y =&#62; 5, x =&#62; 7, energy_gain =&#62; 2 ),                                      
                     ]
    );
        
    # ..with map in DATA of the current file
    $scenario-&#62;get_map_from_DATA();
        
    # set the hero at given position or to a defualt location
    $scenario-&#62;set_hero_position( @ARGV ? @ARGV : &#39;south11&#39; );

    # a basic configuration will use 16 colors
    # use Game::Term::Configuration-&#62;new( colors_map =&#62; 256 )
    # if your console supports them
    my $conf = Game::Term::Configuration-&#62;new();
        
    # hero has to be qualified in the first scenario
    my $hero = Game::Term::Actor::Hero-&#62;new( name =&#62; &#39;My New Hero&#39; );

    # the game object feed with all the above
    my $game = Game::Term::Game-&#62;new( 
                                      debug         =&#62; 0,  
                                      configuration =&#62; $conf, 
                                      scenario      =&#62; $scenario,
                                      hero          =&#62; $hero,

    );

    # start the game loop
    $game-&#62;play();

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
    M                 mm</pre>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="DESCRIPTION"
>DESCRIPTION</a></h1>

<p>Game::Term aims to be a fully usable game engine to produce console games, ie ASCII art games to be run in the Linux console or Windows cmd.exe command prompt. Colors are provided using ansi escape sequences. The engine is at the moment usable but still not complete and only few things are implemented.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="configuration"
>configuration</a></h2>

<p>The configuration of the game engine, handled by the <a href="http://search.cpan.org/perldoc?Game%3A%3ATerm%3A%3AConfiguration" class="podlinkpod"
>Game::Term::Configuration</a> module, stores two kind of informations. The first group is <code>interface</code> and is about the appearence and default directories and files.</p>

<p>The second group is <code>terrains</code> and holds various infos about every possible terrain based on how many colors the engine will use (2, 16 or 256 as specified in the <code>interface</code> section).</p>

<p>Once generated the configuration is saved into the <code>GameTermConfDefault.conf</code> under the game directory and will be loaded from this file preferentially.</p>

<p>The engine lets you to reload the configuration during the game.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="maps"
>maps</a></h2>

<p>The map is rendered on the console screen as a scrollable rectangle of ASCII characters. It is displayed inside a box with the title of the current scenario at the top and a user&#39;s menu at the bottom.</p>

<p>Basically a redraw of the screen is accomplished clearing the buffer with the system call appropriate for the OS in use.</p>

<p>The map is handled by <a href="http://search.cpan.org/perldoc?Game%3A%3ATerm%3A%3AMap" class="podlinkpod"
>Game::Term::Map</a> module.</p>

<p>A valid map is an Array of Arrays each one of the same length containing empty spaces or other characters for various terrains. A map can be contained in a separate file or inside the scenario program under the <code>__DATA__</code> token.</p>

<p>The render engine will transform the map before drawing it to the screen adding colors and other attributes to each tile.</p>

<p>Each tile of the map inside the UI will hold an anonymous array with 3 elements:</p>

<ul>
<li>[0] - the colored character to display ( for the same terrain type one or more characters and colors can be used )</li>

<li>[1] - the original character ( used as terrain identifier )</li>

<li>[2] - 0 if the tile is masked and 1 if it is already discovered (unmasked) and has to be displayed.</li>
</ul>

<p>The map only contains terrain informations, no actors nor the hero.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="UI"
>UI</a></h2>

<p>The User Interface is governed by the <a href="http://search.cpan.org/perldoc?Game%3A%3ATerm%3A%3AUI" class="podlinkpod"
>Game::Term::UI</a> module. It loads and applies a configuration, draws pixels on the console screen and grabs user&#39;s input.</p>

<p>UI will create a frame where a scrolllable map is displayed. Scroll is ruled by hero&#39;s position.</p>

<p>All fancy color effects provided by <a href="http://search.cpan.org/perldoc?Term%3A%3AANSIColor" class="podlinkpod"
>Term::ANSIColor</a> are applied in the UI (Windows user might need to load and run <code>ansicon.exe</code> from <a href="https://github.com/adoxa/ansicon" class="podlinkurl"
>https://github.com/adoxa/ansicon</a> to have ansi sequences correctly interpreted).</p>

<p>Generally the UI will mask parts of the map not yet explored and will put &#34;fog of war&#34; in empty spaces ( plains ) outside hero&#39;s sight.</p>

<p>Even if the map is all discovered only creatures in the hero&#39;s sight are displayed and their moves will trigger a refresh of the map.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="scenarios"
>scenarios</a></h2>

<p>The scenario concept cover two distinct things. Firstly a <code>scenario</code> is a regular Perl program as shown in the synopis: a <code>.pl</code> program that uses the current suit of modules, mainly building up a <a href="http://search.cpan.org/perldoc?Game%3A%3ATerm%3A%3AGame" class="podlinkpod"
>Game::Term::Game</a> object, to start a new game by calling <code>$game-&#62;play()</code></p>

<p>To make this funnier the above perl program will inject into the game object a scenario constitued by a map, some creature lurking on the map and possibly events and more.</p>

<p>The scenario is created and handled using the <a href="http://search.cpan.org/perldoc?Game%3A%3ATerm%3A%3AScenario" class="podlinkpod"
>Game::Term::Scenario</a> module and its few methods.</p>

<p>If an argument is passed to the program setting up the scenario this will be used as hero&#39;s starting position. This argument is passed in like: <code>south5</code> meaning on the south side of the map at tile 5 (starting from 0) or <code>west22</code> or similar. An alternative way of passing hero&#39;s starting position is formed by three arguments (the string <code>middle</code> and <code>y</code> and <code>x</code> coordinates) like: <code>middle 19 72</code> to intend hero enters at row 19 column 72.</p>

<p>The scenario will also sets all default intial values for: the hero position, number and kind of present actors and every other entities a scenario can hold.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="game_state_and_user&#39;s_saves"
>game state and user&#39;s saves</a></h2>

<p>The game object created using <a href="http://search.cpan.org/perldoc?Game%3A%3ATerm%3A%3AGame" class="podlinkpod"
>Game::Term::Game</a> will take track of the game state in a file (normally <code>GameState.sto</code> stored in the main game diretory as stated in the configuration). This file will hold the hero&#39;s state and the information about progress achieved in each scenario.</p>

<p>If the hero come back to an already visited scenario, parts of the map already explored will be visible e and actors already defeated (or enigmas already resolved) will be not present.</p>

<p>This beahviour and the above descripted scenario ability (to receive as argument the hero&#39;s starting position), make a scenario reusable during game different phases.</p>

<p>Eaxample: hero explores part of <code>scenario one</code> (which defaults are stored in <code>scenario_one.pl</code> file) and exits the map entering into <code>scenario two</code> (stored in <code>scenario_two.pl</code>). When they come back to <code>scenario one</code> not the defaults contained in <code>scenario_one.pl</code> file are used but the data about <code>scenario one</code> contained in the <code>GameState.sto</code> file. This is valid for the map, actors and also for events (more on this in a while). So a perl program containing a scenario holds data used first time it is used: after data will be retrieved from the<code>GameState.sto</code> file.</p>

<p>By other hand user can save the game every moment: this action will save a precise snapshot of the game at the current time, in the current scenario. All objects stored in the save file (the game one using the scenario one, the configuration, the hero and all) can be saved and reloaded by the user at any moment. This does not affect the game state file that is modified only exiting a scenario.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="game_object"
>game object</a></h2>

<p>The game object created using <a href="http://search.cpan.org/perldoc?Game%3A%3ATerm%3A%3AGame" class="podlinkpod"
>Game::Term::Game</a> module rules them all.</p>

<p>It holds the main game loop triggered by the <code>$game-&#62;play()</code> call.</p>

<p>It needs to be feed with a scenario and a UI and (if not retrieved looking into the <code>GameState.sto</code> file) with an hero. If present, scenario data will be modified according to <code>GameState.sto</code> informations. The UI, if nothing is specified, will be loaded using values provided by <code>GameTermConfDefault.conf</code> file.</p>

<p>The game object receives user&#39;s command from the UI, performs it&#39;s own operations and instruct the UI on how the screen has to be drawn.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="hero_and_actors"
>hero and actors</a></h2>

<p>Hero (impersoned by the user) and actors belong to the <code>Game::Term::Actor</code> class. Hero in particular is an object of the derived class <code>Game::Term::Actor::Hero</code></p>

<p>The <code>Game::Term::Actor</code> class defines few common attributes and has information used by the movement system. Each actor in the game loop receives an amount of energy as specified by its <code>energy_gain</code> properties. When energy reaches a given treshold the actor can move.</p>

<p>This will results in actors moving at different speed while in reality they just receive less or more moves in respect to the hero.</p>

<p>Hero in addition has a sight that modifies the area of the map currently without the &#34;fog of war&#34; and the amplitude of the explored map. This sight range will be shorter while the hero is inside a wood and greater when hero is on elevated places like hills or mountains.</p>

<p>Walking on different kinds of terrain will result in faster or slower mevements of the hero, simulated timing the speed used to refresh the screen.</p>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="commands"
>commands</a></h2>

<p>User&#39;s commands can be of two distinct kinds: map commands are essentially movements (and few others that also consume a move like using object, or that not count as movement like inspecting the bag) and are issued by the user with the <code>wasd</code> keys. Each keypress will be a separate command. The <code>h</code> command prints a short description of all commands.</p>

<p>Pressing the <code>:</code> key the user enters in <code>command mode</code> where commands available are issued as longer strings possibly with more terms (like in <code>save my_first_save.sav</code> or <code>configuration ./MyCustomConf.yaml</code>). Hitting <code>TAB</code> will expand command names. The command <code>return_to_game</code> is used to return back to the <code>map mode</code>.</p>

<p>Generally every command issued while in <code>map mode</code> will result in a screen redraw but the same is not true for commands issued while in <code>command mode</code> where a pseudo prompt is present.</p>

<p>Currently commands are (as shown by the inline help):</p>

<pre>      MAP MODE (exploration)

      w   walk north
      a   walk west
      s   walk south
      d   walk east

      b   show bag content
      u   use an item in the bag (counts as a move)

      h   show this help

      l   show labels on the map (to be implemented)

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
              bring you back to MAP MODE</pre>

<h2><a class='u' href='#___top' title='click to go to top of document'
name="events_and_timeline"
>events and timeline</a></h2>

<p>Events are the salt and spices of a sceanrio. They are created from the <a href="http://search.cpan.org/perldoc?Game%3A%3ATerm%3A%3AEvent" class="podlinkpod"
>Game::Term::Event</a> class. They can specify different things happening at some time or under certain conditions. For the moment is important to know how they happen and how they modify the game.</p>

<p>Events are created in the scenario (perl program) and passed to the game object in the <code>events =&#62; [...]</code> parameter.</p>

<p>Events not triggered at a given turn are left in the game oject and are checked every game turn to see if they have to be rendered (hero at given tile, doors to other scenarios and alike).</p>

<p>Time events are treated differently: once the game object receives them, it builds up a <b>timeline</b> structure, a queue of game turns containing one, zero or more events each turn.</p>

<p>This <b>timeline</b> will be an array of array, like (* on current turn):</p>

<pre> [
  * undef,              # turn 0 no events
    [ event1 ],         # turn 1 will trigger event1
    undef,              # turn 2 no events
    [ event2, event3 ]  # turn will trigger event2 and then event3
 ]</pre>

<p>Once time events are pushed into the <b>timeline</b> they are removed from the game main events list.</p>

<p>When turn 1 will happen ( turns are count based on hero&#39;s perspective ) the game object will check its own list of event and events contained in the <b>timeline</b> at the given position. In the above example <code>event1</code> is scheduled to run at turn 1 and it is rendered.</p>

<p>If <code>event1</code> has a <code>duration</code> specified another event is spawned automatically, let&#39;s say <code>event1-end</code>, to mark the end of <code>event1</code>.</p>

<p>Let&#39;s continue the above example saying that <code>event1</code> will increase hero&#39;s sight for 3 turns, the following will happen during the event rendering:</p>

<pre> [
    undef,              # turn 0 no events
   *[ event1 ],         # turn 1 will trigger event1
    undef,              # turn 2 no events
    [ event2, event3 ]  # turn 3 will trigger event2 and then event3
    [ event1-end ]      # created automatically by event1
 ]</pre>

<p>Time events and events marked to run only once are then removed from any queue. So at the turn 2 the <b>timeline</b> will be:</p>

<pre> [
    undef,              # turn 0 no events
    [ undef ],          # turn 1 event already rendered is removed
   *undef,              # turn 2 no events
    [ event2, event3 ]  # turn will trigger event2 and then event3
    [ event1-end ]      # created automatically by event1
 ]</pre>

<p>In the current implementation all events must have a valid <code>target</code> or they will be removed from the queue.</p>

<p>To exit from the current scenario entering into another one, basically, does not delete this timeline but will import scheduled timeline events into the timeline of the new scenario. So an effect during 10 turns can be in effect 3 turns in a scenario and 7 turns in the next one (this is valid only for the hero: effects on other actors will end exiting the current scenario).</p>

<p>Events not in the timeline (doors or other events triggered at particular locations) are saved in the <code>GameState.sto</code> file section dedicated to current scenario on exit. These saved events will overwrite events defined in the scenario file when hero will enter it again.</p>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="AUTHOR"
>AUTHOR</a></h1>

<p>LorenzoTa, <code>&#60;lorenzo at cpan.org&#62;</code></p>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="BUGS"
>BUGS</a></h1>

<p>Please report any bugs or feature requests to <code>bug-game::term at rt.cpan.org</code>, or through the web interface at <a href="https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game::Term" class="podlinkurl"
>https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game::Term</a>. I will be notified, and then you&#39;ll automatically be notified of progress on your bug as I make changes.</p>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="SUPPORT"
>SUPPORT</a></h1>

<p>You can find documentation for this module with the perldoc command.</p>

<pre>    perldoc Game::Term</pre>

<p>You can also look for information at:</p>

<ul>
<li>RT: CPAN&#39;s request tracker (report bugs here)
<p><a href="https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game::Term" class="podlinkurl"
>https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game::Term</a></p>
</li>

<li>AnnoCPAN: Annotated CPAN documentation
<p><a href="http://annocpan.org/dist/Game::Term" class="podlinkurl"
>http://annocpan.org/dist/Game::Term</a></p>
</li>

<li>CPAN Ratings
<p><a href="https://cpanratings.perl.org/d/Game::Term" class="podlinkurl"
>https://cpanratings.perl.org/d/Game::Term</a></p>
</li>

<li>Search CPAN
<p><a href="https://metacpan.org/release/Game::Term" class="podlinkurl"
>https://metacpan.org/release/Game::Term</a></p>
</li>
</ul>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="ACKNOWLEDGEMENTS"
>ACKNOWLEDGEMENTS</a></h1>

<h1><a class='u' href='#___top' title='click to go to top of document'
name="LICENSE_AND_COPYRIGHT"
>LICENSE AND COPYRIGHT</a></h1>

<p>Copyright 2019 LorenzoTa.</p>

<p>This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:</p>

<p><a href="http://www.perlfoundation.org/artistic_license_2_0" class="podlinkurl"
>http://www.perlfoundation.org/artistic_license_2_0</a></p>

<p>Any use, modification, and distribution of the Standard or Modified Versions is governed by this Artistic License. By using, modifying or distributing the Package, you accept this license. Do not use, modify, or distribute the Package, if you do not accept this license.</p>

<p>If your Modified Version has been derived from a Modified Version made by someone other than you, you are nevertheless required to ensure that your Modified Version complies with the requirements of this license.</p>

<p>This license does not grant you the right to use any trademark, service mark, tradename, or logo of the Copyright Holder.</p>

<p>This license includes the non-exclusive, worldwide, free-of-charge patent license to make, have made, use, offer to sell, sell, import and otherwise transfer the Package with respect to any patent claims licensable by the Copyright Holder that are necessarily infringed by the Package. If you institute patent litigation (including a cross-claim or counterclaim) against any party alleging that the Package constitutes direct or contributory patent infringement, then this Artistic License to you shall terminate on the date that such litigation is filed.</p>

<p>Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS &#34;AS IS&#39; AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.</p>

<!-- end doc -->

</body></html>
