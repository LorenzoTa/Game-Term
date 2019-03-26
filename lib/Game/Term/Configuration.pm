package Game::Term::Configuration;

use 5.014;
use strict;
use warnings;
use Carp;

use Term::ANSIColor qw(RESET :constants :constants256);

# CLEAR           RESET             BOLD            DARK
# FAINT           ITALIC            UNDERLINE       UNDERSCORE
# BLINK           REVERSE           CONCEALED
 
# BLACK           RED               GREEN           YELLOW
# BLUE            MAGENTA           CYAN            WHITE
# BRIGHT_BLACK    BRIGHT_RED        BRIGHT_GREEN    BRIGHT_YELLOW
# BRIGHT_BLUE     BRIGHT_MAGENTA    BRIGHT_CYAN     BRIGHT_WHITE
 
# ON_BLACK        ON_RED            ON_GREEN        ON_YELLOW
# ON_BLUE         ON_MAGENTA        ON_CYAN         ON_WHITE
# ON_BRIGHT_BLACK ON_BRIGHT_RED     ON_BRIGHT_GREEN ON_BRIGHT_YELLOW
# ON_BRIGHT_BLUE  ON_BRIGHT_MAGENTA ON_BRIGHT_CYAN  ON_BRIGHT_WHITE


# ANSI0  Black (SYSTEM)
# ANSI1  Maroon (SYSTEM)
# ANSI2  Green (SYSTEM)
# ANSI3  Olive (SYSTEM)
# ANSI4  Navy (SYSTEM)
# ANSI5  Purple (SYSTEM)
# ANSI6  Teal (SYSTEM)
# ANSI7  Silver (SYSTEM)
# brigther colors
# ANSI8  Grey (SYSTEM)
# ANSI9  Red (SYSTEM)
# ANSI10  Lime (SYSTEM)
# ANSI11  Yellow (SYSTEM)
# ANSI12  Blue (SYSTEM)
# ANSI13  Fuchsia (SYSTEM)
# ANSI14  Aqua (SYSTEM)
# ANSI15  White (SYSTEM)

sub new{
	my $class = shift;
	my %conf = validate_conf( @_ );
	# if $conf{from} ...
	# read file..
	# import.. 
	my %terrains = terrains_16_colors();
	
	return bless {
				interface => \%conf,
				terrains =>  \%terrains,
	}, $class;
}
sub get_interface{
	my $conf = shift;
	return %{$conf->{interface}};
}
sub get_terrains{
	my $conf = shift;
	return %{$conf->{terrains}};
}
sub terrains_16_colors{
	#		     0 str           1 scalar/[]        2 scalar/[]          3 scalar/[]   4 0..5(5=unwalkable)
# letter used in map, descr  possible renders,  possible fg colors,  bg color,  speed penality
	' ' => [  'plain', ' ', '', '',        0 ],
	A => [ 'bridge', '-', ANSI3,  '',  0 ],
	a => [ 'bridge', '|', ANSI3,  '',  0 ],
	B => [ 'bridge', '/', ANSI3,  '',  0 ], # you need two of this
    b => [ 'bridge', '\\', ANSI3,  '',  0 ],#   ''
	# C 
	# c 
	# D 
	# d 
	# E 
	# e 
	# F 
	# f 
	# G 
	# g 
	# H 
	h => [ 'hill', 'm', [ ANSI3, ANSI2 ],  '',  0.8 ],
	# I 
	# i 
	# J 
	# j ͡
	# K 
	# k 
	# L 
	# l 
	M => [ 'unwalkable mountain', 'M', [ ANSI15, ANSI8 ],  '',  999 ],         # OK ʌ with chcp 65001
	m => [ 'mountain', 'M', [ ANSI3, ANSI2 ],  '',  3 ],
	# N
	# n
	# O 
	# o 
	# P 
	# p
	# Q 
	# q 
	# R 
	# r 
	S => [ 'unwalkable swamp', [qw( ~ - ~ - ~)], ANSI2, ON_YELLOW,  999 ],
	s => [ 'swamp', '-', ANSI3,  '',       1 ],
	T => [ 'unwalkable wood', 'O',   [ ANSI3,ANSI10 ],  '',       999 ], 
	t => [ 'wood', ['O', 'o'], [ ANSI3, ANSI2], '',        0.5 ],
	#t => [  'walkable wood', [qw(O o 0 o O O)], [ ANSI34, ANSI70, ANSI106, ANSI148, ANSI22], '',        0.3 ],
	# U 
	# u
	# V 
	# v 
	#W => [  'deep water', [qw(~ ~ ~ ~),' '], [ ANSI39, ANSI45, ANSI51, ANSI87, ANSI14], UNDERLINE.BLUE, 999 ],
	#w => [  'shallow water', [qw(~ ~ ~ ~),' '], [ ANSI18, ANSI19, ANSI21, ANSI27, ANSI123], '', 2 ],
	W => [ 'deep water', '~',  [ ANSI12, ANSI8, ANSI12 ] , ON_BLUE, 999 ],
	w => [ 'shallow water',[qw(~ - ~ ~)], [ ANSI15, ANSI12 ], '', 2 ],
	
	# X RESERVED for hero in the original map
	# x 
	# Y 
	# y 
	# Z 
	# z
		
}
sub validate_conf{
	my %conf = @_;
	$conf{ map_area_w } //= 50; #80;
	$conf{ map_area_h } //=  20; #20;
	$conf{ menu_area_w } //= $conf{ map_area_w };
	$conf{ menu_area_h } //= 20;

	$conf{ dec_hor }     //= '-';
	$conf{ dec_ver }     //= '|';
	$conf{ ext_tile }	//= 'O'; # ok with chr(119) intersting chr(0) == null 176-178 219
	$conf{ dec_color } //= ANSI1;#''; # apply to dec_hor dec_ver ext_tile
	#$conf{ ext_tile } //= ['O','O',1];
	$conf{ cls_cmd }     //= $^O eq 'MSWin32' ? 'cls' : 'clear';

	$conf{ masked_map }     //= 1;
	$conf{ fog_of_war }		//=1;
	$conf{ fog_char }		//= '.'; #chr(176); 177 178

	$conf{ hero_icon } = 'X'; #chr(2);#'X'; 30 1 2
	$conf{ hero_color } //= ANSI9;
	$conf{ hero_sight } = 5;
	$conf{ hero_slowness } //= 0; # used to microsleep

	$conf{ no_scroll } = 0;

	return %conf;
}

sub color_names_to_ANSI {
	my %conv = (
				Black	=>	ANSI0,
				Maroon	=>	ANSI1,
				Green	=>	ANSI2,
				Olive	=>	ANSI3,
				Navy	=>	ANSI4,
				Purple	=>	ANSI5,
				Teal	=>	ANSI6,
				Silver	=>	ANSI7,
				Grey	=>	ANSI8,
				Red		=>	ANSI9,
				Lime	=>	ANSI10,
				Yellow	=>	ANSI11,
				Blue	=>	ANSI12,
				Fuchsia	=>	ANSI13,
				Aqua	=>	ANSI14,
				White	=>	ANSI15,
				Grey0	=>	ANSI16,
				NavyBlue	=>	ANSI17,
				DarkBlue	=>	ANSI18,
				Blue3	=>	ANSI19,
				Blue3	=>	ANSI20,
				Blue1	=>	ANSI21,
				DarkGreen	=>	ANSI22,
				DeepSkyBlue4	=>	ANSI23,
				DeepSkyBlue4	=>	ANSI24,
				DeepSkyBlue4	=>	ANSI25,
				DodgerBlue3	=>	ANSI26,
				DodgerBlue2	=>	ANSI27,
				Green4	=>	ANSI28,
				SpringGreen4	=>	ANSI29,
				Turquoise4	=>	ANSI30,
				DeepSkyBlue3	=>	ANSI31,
				DeepSkyBlue3	=>	ANSI32,
				DodgerBlue1	=>	ANSI33,
				Green3	=>	ANSI34,
				SpringGreen3	=>	ANSI35,
				DarkCyan	=>	ANSI36,
				LightSeaGreen	=>	ANSI37,
				DeepSkyBlue2	=>	ANSI38,
				DeepSkyBlue1	=>	ANSI39,
				Green3	=>	ANSI40,
				SpringGreen3	=>	ANSI41,
				SpringGreen2	=>	ANSI42,
				Cyan3	=>	ANSI43,
				DarkTurquoise	=>	ANSI44,
				Turquoise2	=>	ANSI45,
				Green1	=>	ANSI46,
				SpringGreen2	=>	ANSI47,
				SpringGreen1	=>	ANSI48,
				MediumSpringGreen	=>	ANSI49,
				Cyan2	=>	ANSI50,
				Cyan1	=>	ANSI51,
				DarkRed	=>	ANSI52,
				DeepPink4	=>	ANSI53,
				Purple4	=>	ANSI54,
				Purple4	=>	ANSI55,
				Purple3	=>	ANSI56,
				BlueViolet	=>	ANSI57,
				Orange4	=>	ANSI58,
				Grey37	=>	ANSI59,
				MediumPurple4	=>	ANSI60,
				SlateBlue3	=>	ANSI61,
				SlateBlue3	=>	ANSI62,
				RoyalBlue1	=>	ANSI63,
				Chartreuse4	=>	ANSI64,
				DarkSeaGreen4	=>	ANSI65,
				PaleTurquoise4	=>	ANSI66,
				SteelBlue	=>	ANSI67,
				SteelBlue3	=>	ANSI68,
				CornflowerBlue	=>	ANSI69,
				Chartreuse3	=>	ANSI70,
				DarkSeaGreen4	=>	ANSI71,
				CadetBlue	=>	ANSI72,
				CadetBlue	=>	ANSI73,
				SkyBlue3	=>	ANSI74,
				SteelBlue1	=>	ANSI75,
				Chartreuse3	=>	ANSI76,
				PaleGreen3	=>	ANSI77,
				SeaGreen3	=>	ANSI78,
				Aquamarine3	=>	ANSI79,
				MediumTurquoise	=>	ANSI80,
				SteelBlue1	=>	ANSI81,
				Chartreuse2	=>	ANSI82,
				SeaGreen2	=>	ANSI83,
				SeaGreen1	=>	ANSI84,
				SeaGreen1	=>	ANSI85,
				Aquamarine1	=>	ANSI86,
				DarkSlateGray2	=>	ANSI87,
				DarkRed	=>	ANSI88,
				DeepPink4	=>	ANSI89,
				DarkMagenta	=>	ANSI90,
				DarkMagenta	=>	ANSI91,
				DarkViolet	=>	ANSI92,
				Purple	=>	ANSI93,
				Orange4	=>	ANSI94,
				LightPink4	=>	ANSI95,
				Plum4	=>	ANSI96,
				MediumPurple3	=>	ANSI97,
				MediumPurple3	=>	ANSI98,
				SlateBlue1	=>	ANSI99,
				Yellow4	=>	ANSI100,
				Wheat4	=>	ANSI101,
				Grey53	=>	ANSI102,
				LightSlateGrey	=>	ANSI103,
				MediumPurple	=>	ANSI104,
				LightSlateBlue	=>	ANSI105,
				Yellow4	=>	ANSI106,
				DarkOliveGreen3	=>	ANSI107,
				DarkSeaGreen	=>	ANSI108,
				LightSkyBlue3	=>	ANSI109,
				LightSkyBlue3	=>	ANSI110,
				SkyBlue2	=>	ANSI111,
				Chartreuse2	=>	ANSI112,
				DarkOliveGreen3	=>	ANSI113,
				PaleGreen3	=>	ANSI114,
				DarkSeaGreen3	=>	ANSI115,
				DarkSlateGray3	=>	ANSI116,
				SkyBlue1	=>	ANSI117,
				Chartreuse1	=>	ANSI118,
				LightGreen	=>	ANSI119,
				LightGreen	=>	ANSI120,
				PaleGreen1	=>	ANSI121,
				Aquamarine1	=>	ANSI122,
				DarkSlateGray1	=>	ANSI123,
				Red3	=>	ANSI124,
				DeepPink4	=>	ANSI125,
				MediumVioletRed	=>	ANSI126,
				Magenta3	=>	ANSI127,
				DarkViolet	=>	ANSI128,
				Purple	=>	ANSI129,
				DarkOrange3	=>	ANSI130,
				IndianRed	=>	ANSI131,
				HotPink3	=>	ANSI132,
				MediumOrchid3	=>	ANSI133,
				MediumOrchid	=>	ANSI134,
				MediumPurple2	=>	ANSI135,
				DarkGoldenrod	=>	ANSI136,
				LightSalmon3	=>	ANSI137,
				RosyBrown	=>	ANSI138,
				Grey63	=>	ANSI139,
				MediumPurple2	=>	ANSI140,
				MediumPurple1	=>	ANSI141,
				Gold3	=>	ANSI142,
				DarkKhaki	=>	ANSI143,
				NavajoWhite3	=>	ANSI144,
				Grey69	=>	ANSI145,
				LightSteelBlue3	=>	ANSI146,
				LightSteelBlue	=>	ANSI147,
				Yellow3	=>	ANSI148,
				DarkOliveGreen3	=>	ANSI149,
				DarkSeaGreen3	=>	ANSI150,
				DarkSeaGreen2	=>	ANSI151,
				LightCyan3	=>	ANSI152,
				LightSkyBlue1	=>	ANSI153,
				GreenYellow	=>	ANSI154,
				DarkOliveGreen2	=>	ANSI155,
				PaleGreen1	=>	ANSI156,
				DarkSeaGreen2	=>	ANSI157,
				DarkSeaGreen1	=>	ANSI158,
				PaleTurquoise1	=>	ANSI159,
				Red3	=>	ANSI160,
				DeepPink3	=>	ANSI161,
				DeepPink3	=>	ANSI162,
				Magenta3	=>	ANSI163,
				Magenta3	=>	ANSI164,
				Magenta2	=>	ANSI165,
				DarkOrange3	=>	ANSI166,
				IndianRed	=>	ANSI167,
				HotPink3	=>	ANSI168,
				HotPink2	=>	ANSI169,
				Orchid	=>	ANSI170,
				MediumOrchid1	=>	ANSI171,
				Orange3	=>	ANSI172,
				LightSalmon3	=>	ANSI173,
				LightPink3	=>	ANSI174,
				Pink3	=>	ANSI175,
				Plum3	=>	ANSI176,
				Violet	=>	ANSI177,
				Gold3	=>	ANSI178,
				LightGoldenrod3	=>	ANSI179,
				Tan	=>	ANSI180,
				MistyRose3	=>	ANSI181,
				Thistle3	=>	ANSI182,
				Plum2	=>	ANSI183,
				Yellow3	=>	ANSI184,
				Khaki3	=>	ANSI185,
				LightGoldenrod2	=>	ANSI186,
				LightYellow3	=>	ANSI187,
				Grey84	=>	ANSI188,
				LightSteelBlue1	=>	ANSI189,
				Yellow2	=>	ANSI190,
				DarkOliveGreen1	=>	ANSI191,
				DarkOliveGreen1	=>	ANSI192,
				DarkSeaGreen1	=>	ANSI193,
				Honeydew2	=>	ANSI194,
				LightCyan1	=>	ANSI195,
				Red1	=>	ANSI196,
				DeepPink2	=>	ANSI197,
				DeepPink1	=>	ANSI198,
				DeepPink1	=>	ANSI199,
				Magenta2	=>	ANSI200,
				Magenta1	=>	ANSI201,
				OrangeRed1	=>	ANSI202,
				IndianRed1	=>	ANSI203,
				IndianRed1	=>	ANSI204,
				HotPink	=>	ANSI205,
				HotPink	=>	ANSI206,
				MediumOrchid1	=>	ANSI207,
				DarkOrange	=>	ANSI208,
				Salmon1	=>	ANSI209,
				LightCoral	=>	ANSI210,
				PaleVioletRed1	=>	ANSI211,
				Orchid2	=>	ANSI212,
				Orchid1	=>	ANSI213,
				Orange1	=>	ANSI214,
				SandyBrown	=>	ANSI215,
				LightSalmon1	=>	ANSI216,
				LightPink1	=>	ANSI217,
				Pink1	=>	ANSI218,
				Plum1	=>	ANSI219,
				Gold1	=>	ANSI220,
				LightGoldenrod2	=>	ANSI221,
				LightGoldenrod2	=>	ANSI222,
				NavajoWhite1	=>	ANSI223,
				MistyRose1	=>	ANSI224,
				Thistle1	=>	ANSI225,
				Yellow1	=>	ANSI226,
				LightGoldenrod1	=>	ANSI227,
				Khaki1	=>	ANSI228,
				Wheat1	=>	ANSI229,
				Cornsilk1	=>	ANSI230,
				Grey100	=>	ANSI231,
				Grey3	=>	ANSI232,
				Grey7	=>	ANSI233,
				Grey11	=>	ANSI234,
				Grey15	=>	ANSI235,
				Grey19	=>	ANSI236,
				Grey23	=>	ANSI237,
				Grey27	=>	ANSI238,
				Grey30	=>	ANSI239,
				Grey35	=>	ANSI240,
				Grey39	=>	ANSI241,
				Grey42	=>	ANSI242,
				Grey46	=>	ANSI243,
				Grey50	=>	ANSI244,
				Grey54	=>	ANSI245,
				Grey58	=>	ANSI246,
				Grey62	=>	ANSI247,
				Grey66	=>	ANSI248,
				Grey70	=>	ANSI249,
				Grey74	=>	ANSI250,
				Grey78	=>	ANSI251,
				Grey82	=>	ANSI252,
				Grey85	=>	ANSI253,
				Grey89	=>	ANSI254,
				Grey93	=>	ANSI255,
	);
	if(exists $conv{$_[0]}){ return $conv{$_[0]} }
	else{croak "'$conv{$_[0]}' is not a valid ANSI color name!"}
}


1; # End of Game::Term::Configuration

__DATA__
=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Game::Term::Config;

    my $foo = Game::Term::Config->new();
    ...


=head1 AUTHOR

LorenzoTa, C<< <lorenzo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game::term at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game::Term>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Term::Config


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