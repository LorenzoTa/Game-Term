package Game::Term::Configuration;

use 5.014;
use strict;
use warnings;

use Term::ANSIColor qw(RESET :constants :constants256);
use constant {
	B_BLACK => ($^O eq 'MSWin32' ? BOLD.BLACK : BRIGHT_BLACK),
    B_RED => ($^O eq 'MSWin32' ? BOLD.RED : BRIGHT_RED),
	B_GREEN => ($^O eq 'MSWin32' ? BOLD.GREEN : BRIGHT_GREEN),
	B_YELLOW => ($^O eq 'MSWin32' ? BOLD.YELLOW : BRIGHT_YELLOW),
	B_BLUE => ($^O eq 'MSWin32' ? BOLD.BLUE : BRIGHT_BLUE),
	B_MAGENTA => ($^O eq 'MSWin32' ? BOLD.MAGENTA : BRIGHT_MAGENTA),
	B_CYAN => ($^O eq 'MSWin32' ? BOLD.CYAN : BRIGHT_CYAN),
	B_WHITE => ($^O eq 'MSWin32' ? BOLD.WHITE : BRIGHT_WHITE),
};

sub new{
	my $class = shift;
	my %conf = validate_conf( @_ );
	
	my %terrains = terrains_16_colors();
	
	return bless {
				configuration => \%conf,
				terrains =>  \%terrains,
	}, $class;
}
sub get_conf{
	my $conf = shift;
	return %{$conf->{configuration}};
}
sub get_terrains{
	my $conf = shift;
	return %{$conf->{terrains}};
}
sub terrains_16_colors{
	#		     0 str           1 scalar/[]        2 scalar/[]          3 scalar/[]   4 0..5(5=unwalkable)
# letter used in map, descr  possible renders,  possible fg colors,  bg color,  speed penality
	' ' => [  'plain', ' ', '', '',        0 ],
	# A 
	# a 
	# B 
	# b 
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
	# h 
	# I 
	# i 
	# J 
	# j ͡
	# K 
	# k 
	# L 
	# l 
	M => [  'unwalkable mountain', chr(156), [ ANSI15],  '',  5 ],         # OK ʌ with chcp 65001
	m => [  'mountain', chr(189), [ ANSI130, ANSI136, ANSI246],  '',  3 ],
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
	# S 
	# s 
	T => [  'unwalkable wood', chr(207),          [ ANSI34, ANSI70, ANSI106, ANSI148, ANSI22],  '',       999 ], 
	t => [  'walkable wood', [chr(172),chr(168)], [ ANSI34, ANSI70, ANSI106, ANSI148, ANSI22], '',        0.3 ],
	#t => [  'walkable wood', [qw(O o 0 o O O)], [ ANSI34, ANSI70, ANSI106, ANSI148, ANSI22], '',        0.3 ],
	# U 
	# u
	# V 
	# v 
	#W => [  'deep water', [qw(~ ~ ~ ~),' '], [ ANSI39, ANSI45, ANSI51, ANSI87, ANSI14], UNDERLINE.BLUE, 999 ],
	#w => [  'shallow water', [qw(~ ~ ~ ~),' '], [ ANSI18, ANSI19, ANSI21, ANSI27, ANSI123], '', 2 ],
	W => [  'deep water', chr(171), [ ANSI39, ANSI45, ANSI51, ANSI87, ANSI14], UNDERLINE.BLUE, 999 ],
	w => [  'shallow water', chr(171), [ ANSI18, ANSI19, ANSI21, ANSI27, ANSI123], '', 2 ],
	
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
	$conf{ dec_color } //= YELLOW;#''; # apply to dec_hor dec_ver ext_tile
	#$conf{ ext_tile } //= ['O','O',1];
	$conf{ cls_cmd }     //= $^O eq 'MSWin32' ? 'cls' : 'clear';

	$conf{ masked_map }     //= 1;
	$conf{ fog_of_war }		//=0;
	$conf{ fog_char }		//= '.'; #chr(176); 177 178

	$conf{ hero_icon } = 'X'; #chr(2);#'X'; 30 1 2
	$conf{ hero_color } //= B_RED;
	$conf{ hero_sight } = 10;
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