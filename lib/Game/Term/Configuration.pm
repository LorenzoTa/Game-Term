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

# # system dark
# Black Maroon Green Olive Navy Purple Teal Silver 
# # system bright
# Grey Red Lime Yellow Blue Fuchsia Aqua White
# # 256 colors 
# Grey0 NavyBlue DarkBlue Blue3 Blue3 Blue1 DarkGreen DeepSkyBlue4 DeepSkyBlue4 DeepSkyBlue4 DodgerBlue3 DodgerBlue2
# Green4 SpringGreen4 Turquoise4 DeepSkyBlue3 DeepSkyBlue3 DodgerBlue1 Green3 SpringGreen3 DarkCyan LightSeaGreen
# DeepSkyBlue2 DeepSkyBlue1 Green3 Spring Green3 SpringGreen2 Cyan3 DarkTurquoise Turquoise2 Green1 SpringGreen2
# SpringGreen1 MediumSpringGreen Cyan2 Cyan1 DarkRed DeepPink4 Purple4 Purple4 Purple3 BlueViolet Orange4 Grey37
# MediumPurple4 SlateBlue3 SlateBlue3 RoyalBlue1 Chartreuse4 DarkSeaGreen4 PaleTurquoise4 SteelBlue SteelBlue3
# CornflowerBlue Chartreuse3 DarkSeaGreen4 CadetBlue CadetBlue SkyBlue3 SteelBlue1 Chartreuse3 PaleGreen3 SeaGreen3
# Aquamarine3 MediumTurquoise SteelBlue1 Chartreuse2 SeaGreen2 SeaGreen1 SeaGreen1 Aquamarine1 DarkSlateGray2 
# DarkRed DeepPink4 DarkMagenta DarkMagenta DarkViolet Purple Orange4 LightPink4 Plum4 MediumPurple3 MediumPurple3
# SlateBlue1 Yellow4 Wheat4 Grey53 LightSlateGrey MediumPurple LightSlateBlue Yellow4 DarkOliveGreen3 DarkSeaGreen
# LightSkyBlue3 LightSkyBlue3 SkyBlue2 Chartreuse2 DarkOliveGreen3 PaleGreen3 DarkSeaGreen3 DarkSlateGray3 SkyBlue1
# Chartreuse1 LightGreen LightGreen PaleGreen1 Aquamarine1 DarkSlateGray1 Red3 DeepPink4 MediumVioletRed Magenta3
# DarkViolet Purple DarkOrange3 IndianRed HotPink3 MediumOrchid3 MediumOrchid MediumPurple2 DarkGoldenrod 
# LightSalmon3 RosyBrown Grey63 MediumPurple2 MediumPurple1 Gold3 DarkKhaki NavajoWhite3 Grey69 LightSteelBlue3
# LightSteelBlue Yellow3 DarkOliveGreen3 DarkSeaGreen3 DarkSeaGreen2 LightCyan3 LightSkyBlue1 GreenYellow
# DarkOliveGreen2 PaleGreen1 DarkSeaGreen2 DarkSeaGreen1 PaleTurquoise1 Red3 DeepPink3 DeepPink3 Magenta3 Magenta3
# Magenta2 DarkOrange3 IndianRed HotPink3 HotPink2 Orchid MediumOrchid1 Orange3 LightSalmon3 LightPink3 Pink3 Plum3
# Violet Gold3 LightGoldenrod3 Tan MistyRose3 Thistle3 Plum2 Yellow3 Khaki3 LightGoldenrod2 LightYellow3 Grey84
# LightSteelBlue1 Yellow2 DarkOliveGreen1 DarkOliveGreen1 DarkSeaGreen1 Honeydew2 LightCyan1 Red1 DeepPink2
# DeepPink1 DeepPink1 Magenta2 Magenta1 OrangeRed1 IndianRed1 IndianRed1 HotPink HotPink MediumOrchid1 DarkOrange
# Salmon1 LightCoral PaleVioletRed1 Orchid2 Orchid1 Orange1 SandyBrown LightSalmon1 LightPink1 Pink1 Plum1 Gold1
# LightGoldenrod2 LightGoldenrod2 NavajoWhite1 MistyRose1 Thistle1 Yellow1 LightGoldenrod1 Kh
# aki1 Wheat1 Cornsilk1 Grey100 Grey3 Grey7 Grey11 Grey15 Grey19 Grey23 Grey27 Grey30 Grey35 Grey39 Grey42 Grey46
# Grey50 Grey54 Grey58 Grey62 Grey66 Grey70 Grey74 Grey78 Grey82 Grey85 Grey89 Grey93

sub new{
	my $class = shift;
	my %conf = validate_conf( @_ );
	
	# if $conf{from} ...
	# read file..
	# import.. 
	# manage palette
	my %terrains;
	if ( ! exists $conf{map_colors}  ){
		%terrains = terrains_16_colors();
	}
	elsif ( $conf{map_colors} == 256 ){
		%terrains = terrains_256_colors();
	}
	elsif ( $conf{map_colors} == 16 ){
		%terrains = terrains_16_colors();
	}
	elsif ( $conf{map_colors} == 2 ){
		%terrains = terrains_2_colors();
		# also clear colors for interface colored elements
		$conf{dec_color}=$conf{hero_color}='';
	}
	else{ %terrains = terrains_16_colors(); }
	
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
sub terrains_2_colors{
	my %terr = terrains_16_colors();
	%terr = map{ $_ => [ $terr{$_}[0],$terr{$_}[1],'','',$terr{$_}[4] ] } keys %terr;
}
sub terrains_16_colors{
	#		     0 str           1 scalar/[]        2 scalar/[]          3 scalar/[]   4 0..5(5=unwalkable)
# letter used in map, descr  possible renders,  possible fg colors,  bg color,  speed penality
	' ' => [  'plain', ' ', '', '',        0 ],
	A => [ 'bridge', '-', 'Maroon',  '',  0 ],
	a => [ 'bridge', '|', 'Maroon',  '',  0 ],
	B => [ 'bridge', '/', 'Maroon',  '',  0 ], # you need two of this
    b => [ 'bridge', '\\', 'Maroon',  '',  0 ],#   ''
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
	h => [ 'hill', 'm', [ 'Olive', 'Green' ],  '',  0.8 ],
	# I 
	# i 
	# J 
	# j ͡
	# K 
	# k 
	# L 
	# l 
	M => [ 'unwalkable mountain', 'M', [ 'Grey', 'Grey' ],  '',  999 ],         # 
	m => [ 'mountain', 'M', [ 'Olive', 'Green' ],  '',  3 ],
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
	S => [ 'unwalkable swamp', [qw( ~ - ~ - ~)], 'Green', 'On_Olive',  999 ],
	s => [ 'swamp', '-', 'Olive',  '',       1 ],
	T => [ 'unwalkable wood', 'O',   [ 'Olive', 'Lime' ],  '',       999 ], 
	t => [ 'wood', ['O', 'o'], [ 'Olive', 'Green'], '',        0.5 ],
	#t => [  'walkable wood', [qw(O o 0 o O O)], [ ANSI34, ANSI70, ANSI106, ANSI148, ANSI22], '',        0.3 ],
	# U 
	# u
	# V 
	# v 
	#W => [  'deep water', [qw(~ ~ ~ ~),' '], [ ANSI39, ANSI45, ANSI51, ANSI87, ANSI14], UNDERLINE.BLUE, 999 ],
	#w => [  'shallow water', [qw(~ ~ ~ ~),' '], [ ANSI18, ANSI19, ANSI21, ANSI27, ANSI123], '', 2 ],
	W => [ 'deep water', '~',  [ qw(DarkBlue DarkBlue Blue) ] , 'On_Navy', 999 ],
	w => [ 'shallow water',[qw(~ - ~ ~)], [ qw(Blue White) ], 'On_Blue', 2 ],
	
	# X RESERVED for hero in the original map
	# x 
	# Y 
	y => [ 'wood', '^', [ 'Olive', 'Green'], '',        0.5 ],
	# Z 
	# z
		
}

sub terrains_256_colors{
	#		     0 str           1 scalar/[]        2 scalar/[]          3 scalar/[]   4 0..5(5=unwalkable)
# letter used in map, descr  possible renders,  possible fg colors,  bg color,  speed penality
	' ' => [  'plain', ' ', '', '',        0 ],
	A => [ 'bridge', '-', 'Olive',  '',  0 ],
	a => [ 'bridge', '|', 'Olive',  '',  0 ],
	B => [ 'bridge', '/', 'Olive',  '',  0 ], # you need two of this
    b => [ 'bridge', '\\', 'Olive',  '',  0 ],#   ''
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
	h => [ 'hill', 'm', [ 'Olive', 'Green' ],  '',  0.8 ],
	# I 
	# i 
	# J 
	# j ͡
	# K 
	# k 
	# L 
	# l 
	M => [ 'unwalkable mountain', 'M', [ 'Grey', 'Grey' ],  '',  999 ],         # 
	m => [ 'mountain', 'M', [ 'Olive', 'Green' ],  '',  3 ],
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
	S => [ 'unwalkable swamp', [qw( ~ - ~ - ~)], 'DarkSeaGreen4', 'On_Yellow4',  999 ],
	s => [ 'swamp', '-', [qw( Gold3 Khaki3 DarkOliveGreen1)],  '',       1 ],
	T => [ 'unwalkable wood', 'O', [ qw( DarkGreen Green4 DarkGreen Green4 DarkGreen Green4 Orange4 Yellow4 DarkOrange3)], 'On_Grey7',  999 ], 
	t => [ 'wood', ['O', 'o'], [ qw( DarkGreen Green4 DarkGreen Green4 DarkGreen Green4 Orange4 Yellow4 DarkOrange3)], '',        0.5 ],
	#t => [  'walkable wood', [qw(O o 0 o O O)], [ ANSI34, ANSI70, ANSI106, ANSI148, ANSI22], '',        0.3 ],
	# U 
	# u
	# V 
	# v 
	#W => [  'deep water', [qw(~ ~ ~ ~),' '], [ ANSI39, ANSI45, ANSI51, ANSI87, ANSI14], UNDERLINE.BLUE, 999 ],
	#w => [  'shallow water', [qw(~ ~ ~ ~),' '], [ ANSI18, ANSI19, ANSI21, ANSI27, ANSI123], '', 2 ],
	W => [ 'deep water', '~',  [qw(DodgerBlue3 DeepSkyBlue2 Turquoise2)] , [qw(On_DarkBlue On_Blue3)], 999 ],
	w => [ 'shallow water',[qw(~ - ~ ~)], [qw(DodgerBlue3 DeepSkyBlue2 Turquoise2)], [qw(On_DeepSkyBlue4 On_DeepSkyBlue3)], 2 ],
	
	# X RESERVED for hero in the original map
	# x 
	# Y 
	y => [ 'wood', '^', [ 'Olive', 'Green'], '',        0.5 ],
	# Z 
	# z
		
}

sub validate_conf{
	my %conf = @_;
	
	if( $conf{map_colors} ){
		croak "configuration 'colors' accepts 2, 16 or 256" 
			unless $conf{map_colors} =~/^(2|16|256)$/;
	}
	
	$conf{ map_area_w } //= 50; #80;
	$conf{ map_area_h } //=  20; #20;
	$conf{ menu_area_w } //= $conf{ map_area_w };
	$conf{ menu_area_h } //= 20;

	$conf{ dec_hor }     //= '-';
	$conf{ dec_ver }     //= '|';
	$conf{ ext_tile }	//= 'O'; # ok with chr(119) intersting chr(0) == null 176-178 219
	$conf{ dec_color } //= 'Maroon' ;#''; # apply to dec_hor dec_ver ext_tile
	#$conf{ ext_tile } //= ['O','O',1];
	$conf{ cls_cmd }     //= $^O eq 'MSWin32' ? 'cls' : 'clear';

	$conf{ masked_map }     //= 1;
	$conf{ fog_of_war }		//=1;
	$conf{ fog_char }		//= '.'; #chr(176); 177 178

	$conf{ hero_icon } = 'X'; #chr(2);#'X'; 30 1 2
	$conf{ hero_color } //= 'Red';
	$conf{ hero_sight } = 5;
	$conf{ hero_slowness } //= 0; # used to microsleep

	$conf{ no_scroll } = 0;

	return %conf;
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