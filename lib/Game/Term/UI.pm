package Game::Term::UI;

use 5.014;
use strict;
use warnings;
use Term::ReadKey;
use Term::ReadLine;
use List::Util qw( max min );
use Term::ANSIColor qw(RESET :constants :constants256);
use Time::HiRes qw ( sleep );
use Carp;
use YAML::XS qw(Dump DumpFile LoadFile);

use Game::Term::Configuration;
use Game::Term::Map;

BEGIN {
		# https://www.perlmonks.org/?node_id=1108329
        # you can force Term::ReadLine to load the ::Perl
        # by setting the ENV PERL_RL variable
        # but you have to do it in a begin block
        # before the use statement
        # try to comment next line: probably ::Perl will be loaded
        # anyway if it is installed
        # try to set to a non available sub module
        # see details: https://metacpan.org/pod/Term::ReadLine#ENVIRONMENT
     $ENV{PERL_RL}="Perl";
        # on win32 systems it ENV TERM is 'dumb'
        # autocompletion is not possible.
        # try to comment next line on win32 and watch how does not work
        # see also http://bvr.github.io/2010/11/term-readline/
     $ENV{TERM} = 'not dumb' if $^O eq 'MSWin32';
}


our $VERSION = '0.01';

our $debug = 0;
our $noscroll_debug = 1;

# terrain is class data!!
my %terrain;

#my $term = Term::ReadLine->new('Game Term');
# $term->Attribs->{completion_function} = sub {
            # my ($text, $line, $start) = @_;
            # # uncomment next line to see debug stuff while you stress autocomplete
            # #print 'DEBUG: $text, $line, $start = >'.(join '< >',$text, $line, $start)."<\n";
            # #return grep { /^$text/i } sort keys %commands ;
			# return grep { /^$text/i } sort qw( save load return_to_game configuration show_legenda exit ) ;
    # };
# SOME NOTES ABOUT MAP:
# The map is initially loaded from the data field of the Game::Term::Map object.
# It is the AoA containing one character per tile (terrains).
# This original AoA is passed to set_map_and_hero() where it will be enlarged depending
# on the map_area settings (the display window). Here the offsets used in print will be calculated.
# Then beautify_map() will modify tiles of the map using colors and deciding which character to use
# when display the map. Tiles of the map will also be transformed into anonymous arrays to hold other
# types of informations.

# Each tile will end to be:  [ 0:to_display,  1:original_terrain_letter,  2:unmasked ]


sub new{
	my $class = shift;
	my %params = @_;
	my $conf_obj = $params{configuration};
	
	$debug = $params{debug} // 0;
	$noscroll_debug = $params{noscroll_debug} // 0;
	my $ui = bless {
				#%interface_conf
	}, $class;
	$ui->{title} = $params{title} // 'TITLE';
	$ui->{map} = $params{map} // Game::Term::Map->new(  )->{data}; 
	$ui->load_configuration( $params{configuration} );
	# $ui->init();	
	# local $ui->{map} = [$ui->{map}[0][0]];
					# use Data::Dump; dd $ui;#exit;
	$ui->{reader} = Term::ReadLine->new('Game Term');
	$ui->{reader}->Attribs->{completion_function} = sub {
            my ($text, $line, $start) = @_;
            # uncomment next line to see debug stuff while you stress autocomplete
            #print 'DEBUG: $text, $line, $start = >'.(join '< >',$text, $line, $start)."<\n";
            #return grep { /^$text/i } sort keys %commands ;
			return grep { /^$text/i } sort qw( save load return_to_game configuration show_legenda help exit ) ;
    };
	# get HERO passed by Game object
	$ui->{hero} = $params{hero};
	return $ui;	
}


sub load_configuration{
	my $ui = shift;
	my $conf_from = shift;
	my $conf_obj;
	# CONFIGURATION provided as object
	if ( $conf_from and ref $conf_from eq 'Game::Term::Configuration'){
		$conf_obj = $conf_from;
		#delete $ui->{configuration}; ??????????????
		print "DEBUG: configuration provided as object\n" if $debug;
	}
	# CONFIGURATION provided as file
	elsif ($conf_from and -e -s -f -r $conf_from ){ 
		$conf_obj = Game::Term::Configuration->new( from => $conf_from );
		print "DEBUG: configuration provided as file\n" if $debug;
	}
	# nothing provided as CONFIGURATION loading empty one
	else{
		$conf_obj = Game::Term::Configuration->new();
		print "DEBUG: no specific configuration provided, loading a basic one\n" if $debug;
	}
	# terrain is class data!!
	%terrain = $conf_obj->get_terrains();
	print "DEBUG: terrain:\n" if $debug > 1;
	foreach my $ter(sort keys %terrain){
		
		print "\t '$ter' =>  [ ",
			(join ', ',map{ ref $_ eq 'ARRAY' ? "[qw( @$_ )]" : "'$_'" }@{$terrain{$ter}}),
			" ],\n" if $debug > 1;
		# foreground colors
		$terrain{$ter}->[2] =  ref $terrain{$ter}->[2] eq 'ARRAY' ?
								[ map{ $ui->color_names_to_ANSI($_) }@{$terrain{$ter}->[2]} ] : 
								( defined  $terrain{$ter}->[3] ? $ui->color_names_to_ANSI( $terrain{$ter}->[2] ):'');
		# eventual background colors						
		$terrain{$ter}->[3] =  ref $terrain{$ter}->[3] eq 'ARRAY' ?
								[map{ $ui->color_names_to_ANSI($_) }@{$terrain{$ter}->[3]} ] : 
								( defined  $terrain{$ter}->[3] ? $ui->color_names_to_ANSI( $terrain{$ter}->[3] ):'');
	}
	# INERFACE: translate color names into ANSI constant
	# ...
	my %interface_conf = $conf_obj->get_interface();
	print "DEBUG: interface:\n",map{ "\t$_ => '$interface_conf{$_}'\n" } sort keys %interface_conf if $debug > 1;
	# translate color names to ANSIx
	#$interface_conf{hero_color} = $ui->color_names_to_ANSI($interface_conf{hero_color});
	$interface_conf{dec_color} = $ui->color_names_to_ANSI($interface_conf{dec_color});
	# apply
	foreach my $key ( keys %interface_conf ){
		$ui->{ $key } = $interface_conf{ $key };	#?????????????????????????????????????????????????
	}
	#$ui->init();
}

sub init{
	my $ui = shift;
		
	print "DEBUG: original received map:\n" if $debug > 1;
	print map{ join'',@$_,$/ } @{$ui->{map}} if $debug > 1;
		
	$ui->set_map_and_hero();
	print "DEBUG: NEW MAP: rows: 0..$#{$ui->{map}} cols: 0..$#{$ui->{ map }[0]}\n" if $debug;
	
	$ui->set_map_offsets();
	# local $ui->{map} = [$ui->{map}[0][0]];
	# use Data::Dump; dd $ui; #exit;
}

sub get_user_command{
		my $ui = shift;
		# COMMAND MODE
		if ( $ui->{mode} and $ui->{mode} eq 'command' ){
			
			ReadMode 'normal';
			my $line = $ui->{reader}->readline('>');
			return unless $line;
			chomp $line;
			$line=~s/\s+$//g;
			my ($cmd,@args)= split /\s+/,$line;
			if ( $cmd ){
				return ($cmd, @args);
			}
			# if ($commands{$cmd}){
				# # me NO
				# # $ui->$commands{$cmd}->();
				# # ME OK
				# #$commands{$cmd}->($ui,@args);
				# # Corion NO
				# # my $method = $ui->can( $commands{$cmd} );
				# # return $ui->$method();
				# # <mst> because ->can only looks up methods by name
				# # <mst> my $method = $commands{$cmd}; $ui->$method() would work
				# # <mst> which is the long form version of $ui->${\$commands{$cmd}}()
				# # choroba # NO
				# #$ui->${\$commands{$cmd}}->();
				# # <mst>the last -> is the error
				# # <mst>that's not how method calls in perl look
				# # <mst>that's calling the method, then trying to use the return value of the method as a subref
				# #
				# # integral and mst on irc
				# return  $ui->${\$commands{$cmd}}(@args)  #OK
				# # also OK 
				# #return $commands{$cmd}->($ui,@args);
			# }
			else{return}
		}	
		# MAP MODE
		else{
			ReadMode 'cbreak';
			my $key = ReadKey(0);
			return $key;
		}
}


sub set_map_offsets{
	my $ui = shift;	
	if ( $ui->{hero_side} eq 'S' ){		
		$ui->{map_off_x} =  $ui->{hero}{x} - $ui->{map_area_w} / 2; 
		$ui->{map_off_y} =  $ui->{hero}{y} - $ui->{map_area_h} ;		
		print "DEBUG: SOUTH map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n" if $debug;
	}
	elsif ( $ui->{hero_side} eq 'N' ){		
		$ui->{map_off_x} =  $ui->{hero}{x} - $ui->{map_area_w} / 2;
		$ui->{map_off_y} =  $ui->{hero}{y}   ;		
		print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n" if $debug;
	}
	elsif ( $ui->{hero_side} eq 'E' ){		
		$ui->{map_off_x} = $ui->{hero}{x} - $ui->{map_area_w} ;
		$ui->{map_off_y} =  $ui->{hero}{y} - $ui->{map_area_h} / 2; # ok ma no ... f di hero.. $ui->{map_area_h} + 1;
		print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n" if $debug;
	}	
	elsif ( $ui->{hero_side} eq 'W' ){		
		$ui->{map_off_x} = $ui->{hero}{x} - 1; # ???? 
		$ui->{map_off_y} = $ui->{hero}{y} - $ui->{map_area_h} / 2;		
		print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n" if $debug;
	}
	# M
	elsif ( $ui->{hero_side} eq 'M' ){		
		$ui->{map_off_x} = $ui->{hero}{x} - $ui->{map_area_w} / 2;
		$ui->{map_off_y} = $ui->{hero}{y} - $ui->{map_area_h} / 2;		
		print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n" if $debug;
	}
	else{die}

}
sub draw_map{
	my $ui = shift;
	my @actors = @_;
	# clear screen
	system $ui->{ cls_cmd } unless $debug;
	
	# get area of currently hero's seen tiles (by coords)
	my %seen = $ui->illuminate();
	
	# LOCALIZING
	# goto LOOP needed to have multiple locals to work (thanks mst from irc)
	my $index = 0;
	LOOP_ACTORS:
	# actor's tile localized to  their ICON
	local $ui->{map}[ $actors[$index]->{y} ][ $actors[$index]->{x} ][0] 
		= 
	$ui->color_names_to_ANSI($actors[$index]->{color}).$actors[$index]->{icon}.RESET
	if $actors[$index] and exists $seen{ $actors[$index]->{y}.'_'.$actors[$index]->{x} };
	
	# localize actors LABELS -- OK version
	# local @{$ui->{map}[ $actors[$index]{y}+1 ]}
				# [ $actors[$index]{x}..$actors[$index]{x}+length($actors[$index]{name})-1 ]	
		# =
		# map{[$_,'_',1]}(split //,$actors[$index]->{name})
		# if 	$ui->{map_labels}												and
			# $actors[$index] 												and 
			# exists $seen{ $actors[$index]{y}.'_'.$actors[$index]{x} }	 	and
			# $actors[$index]{y}+1 <= $ui->{map_off_y} + $ui->{map_area_h} 	and
			# $actors[$index]{x}+length($actors[$index]->{name})-1 < $ui->{map_off_x} + $ui->{map_area_w};
	
	# localize actors LABELS
	# my @letters = split //,$actors[$index]->{name};
	# local (  @{$ui->{map}[ $actors[$index]{y}+1 ]}
				 # [ $actors[$index]{x}..$actors[$index]{x}+length($actors[$index]{name})-1 ] )
			
	# = 
	# map { my $local = $ui->{map}[ $actors[$index]{y}+1 ][ $actors[$index]{x}+$_ ]; 
			# $local->[0] = $letters[$_]; 
			# $local 
	
	# } 0..$#letters;
	
	# NO!! "We don't have magical writable multidimensional slicing on our arrays" hobbs
	# local $ui->{map}[ $actors[$index]{y}+1 ]
					# [ $actors[$index]{x}..$actors[$index]{x}+length($actors[$index]{name})-1 ]
					# [0]
		# =
		# (split //,$actors[$index]->{name})
		# if 	$ui->{map_labels}												and
			# $actors[$index] 												and 
			# exists $seen{ $actors[$index]{y}.'_'.$actors[$index]{x} }	 	and
			# $actors[$index]{y}+1 <= $ui->{map_off_y} + $ui->{map_area_h} 	and
			# $actors[$index]{x}+length($actors[$index]->{name})-1 < $ui->{map_off_x} + $ui->{map_area_w};	
	$index++; 
	goto LOOP_ACTORS if $index <= $#actors;
 	
	
	
	# localize HERO
	local $ui->{map}[ $ui->{hero}{y} ][ $ui->{hero}{x} ] = $ui->{hero}{icon}; 
	
	# TITLE AREA:
	# print decoration first row
	print 	$ui->{dec_color},' o',
			$ui->{ dec_hor } x ( $ui->{ map_area_w } ),
			$ui->{dec_color},'o',RESET,"\n";
			print ' ',$ui->{ dec_ver };
			print ' ' x 1,
			      $ui->{ title },
				  ' ' x ($ui->{ map_area_w } - 
						 length ($ui->{ title }) - 1 ),
				  $ui->{ dec_ver },"\n";	
				
	
	# MAP AREA:
	# print decoration first row
	print 	$ui->{dec_color},' o',
			$ui->{ dec_hor } x ( $ui->{ map_area_w } ),
			$ui->{dec_color},'o',RESET,"\n";	
	
	# print map body with decorations
	# iterate ROWS by indexe 
	foreach my $row ( $ui->{map_off_y}..$ui->{map_off_y} + $ui->{map_area_h}   ){ 

		# print decoration vertical
		print ' ',$ui->{ dec_ver };
		# print ext_tile entire row if needed
		if ($row < 0 or $row > $#{$ui->{map}} ){ 
			print +($ui->{ext_tile} x $ui->{ map_area_w }),$ui->{ dec_ver },"\n";
			next;
		}	
		# iterate COLUMNS by indexe  
		foreach my $col  ( $ui->{map_off_x} + 1 ..$ui->{map_off_x} + $ui->{map_area_w}  ){
				# print ext_tile column if needed
				if( $col < 0 or $col > $#{$ui->{map}[0]} ){
					print $ui->{ext_tile};
					next;
				}
					
				# if is seen (in the radius of illuminate) and still masked
				if ( $seen{$row.'_'.$col} and $ui->{map}[$row][$col][2] == 0 ){
					# set unmasked
					$ui->{map}[$row][$col][2] = 1;
					# print display
					print $ui->{map}[$row][$col][0];					
				}
				# already unmasked but empty space (fog of war)
				elsif( 	
				$row <= $#{$ui->{map}} and
				$col <= $#{$ui->{map}->[0]}	and
						$ui->{map}[$row][$col][2] == 1 		and 
						$ui->{map}[$row][$col][1] eq ' ' 	and # WITH [0]FAILS!!!!!
						$ui->{fog_of_war}					and
						!$seen{$row.'_'.$col}
					)
				{ 
					print $ui->{fog_char} ;
				}
				# already unmasked: print display 
				elsif( 
				$row <= $#{$ui->{map}} and
				$col <= $#{$ui->{map}->[0]}	and
						$ui->{map}[$row][$col][2] == 1 )
				{ 
					print $ui->{map}[$row][$col][0]; 
				}
				# print ' ' if still masked
				else{ print ' '}
		}
		# print decoration vertical and newline
		print +($ui->{dec_color} 						?
					$ui->{dec_color}.$ui->{ dec_ver }.RESET :
					$ui->{ dec_ver }),"\n" ;
	}	
	# print decoration last row
	print 	$ui->{dec_color},' o',
			$ui->{ dec_hor } x ( $ui->{ map_area_w } ),
			$ui->{dec_color},'o',RESET,"\n";	
	
}


sub must_scroll{
	my $ui = shift;
	return 0 if $ui->{no_scroll};
	return 1 if $ui->{scrolling};
	if(	 
		$ui->{hero}{y} < $ui->{no_scroll_area}{min_y} or
		$ui->{hero}{y} > $ui->{no_scroll_area}{max_y} or
		$ui->{hero}{x} < $ui->{no_scroll_area}{min_x} or
		$ui->{hero}{x} > $ui->{no_scroll_area}{max_x} #and $ui->{scrolling} == 0
	
	){
		print "DEBUG: OUT of scrolling area\n" if $debug;
		$ui->{scrolling} = 1;
		return 1;
	}
	else { return 0 }

}
sub illuminate{
	my $ui = shift;
	my %ret;
	my $max_y = $ui->{hero}{y}  + $ui->{hero}{sight} < $#{ $ui->{map} } 	?
				$ui->{hero}{y}  + $ui->{hero}{sight}						:
				$#{ $ui->{map} };
				
	foreach my $row ( $ui->{hero}{y} - $ui->{hero}{sight}  .. $max_y ){
		my $delta_x = $ui->{hero}{sight} ** 2 - ($ui->{hero}{y} - $row) ** 2;
		if( $delta_x >= 0 ){				
				$delta_x = int sqrt $delta_x;			
				my $low = max 0, $ui->{hero}{x} - $delta_x;
				my $high = min $#{ $ui->{map}->[$row] }, $ui->{hero}{x} + $delta_x;
				map { $ret{ $row.'_'.$_ }++ } $low .. $high;				
		}
	}
	return %ret;
}

		
sub draw_menu{
	my $ui = shift;
	my $turn = shift;
	my $hero = shift;
	my $messages = shift;
	# MENU AREA:
	# print decoration first row
	print 	$ui->{dec_color},' o',
			$ui->{ dec_hor } x ( $ui->{ map_area_w } ),
			$ui->{dec_color},'o',RESET,"\n";	
	# menu data: hero
	print ' ',$ui->{ dec_ver }."(turn $turn) ".
			"$hero->{name} at y: $hero->{y} ".
			"x: $hero->{x} (".($hero->{on_tile}//'').")\n";
	if ($messages){
		print ' ',$ui->{ dec_ver }.$_."\n" for @$messages;
	}
}

sub set_map_and_hero{
	my $ui = shift;

	my $original_map_w = $#{$ui->{map}->[0]} + 1;
	my $original_map_h = $#{$ui->{map}} + 1;
	
	$ui->set_hero_pos();
	
	# HERO beautify happens in Game.pm after import from GameState.sto !!
	
	$ui->beautify_map();		
	
	$ui->set_no_scrolling_area();
	
	if ( $debug > 1 and $ui->{hero_side} ne 'M' ){
		local $ui->{map}->[$ui->{no_scroll_area}{min_y}][$ui->{no_scroll_area}{min_x}] = ['+', '', 1];
		local $ui->{map}->[$ui->{no_scroll_area}{max_y}][$ui->{no_scroll_area}{max_x}] = ['+', '', 1];
	
		print "DEBUG: map beautified ( now each tile is [to_display,terrain letter, masked] ) with no_scroll vertexes (+ signs):\n",
			map{ join'',( map{ $_->[0] }
							@$_ ),$/ 
				} @{$ui->{map}};
	}
		
}

sub beautify_map{
	# letter used in map, descr  possible renders,  possible fg colors,   speed penality
	my $ui = shift;
	# ITERATE ROWS by index
	foreach my $row( 0..$#{$ui->{map}} ){
		# ITERATE COLUMNS by index
		foreach my $col( 0 .. $#{$ui->{map}->[0]} ){
			
			my $is_a_reload = 0;
			my $previous_unmasked;
			# to allow configuration reload:
			# IF was already processed: save masked/unmasked bit 
			# and reverse from ARRAY to chr			
			if (ref $ui->{map}[$row][$col] eq 'ARRAY'){
				$is_a_reload = 1;
				$previous_unmasked = $ui->{map}[$row][$col]->[2];
				$ui->{map}[$row][$col] = $ui->{map}[$row][$col]->[1];#die"[$original_letter]";
								
			}
			# if the letter is defined in %terrain
			if(exists $terrain{ $ui->{map}[$row][$col] } ){
				# FOREGROUND COLOR 
				my $color = ref $terrain{ $ui->{map}[$row][$col] }[2] eq 'ARRAY' 	?
					$terrain{ $ui->{map}[$row][$col] }[2]->
						[int( rand( $#{$terrain{ $ui->{map}[$row][$col] }[2]}+1))]  :
							$terrain{ $ui->{map}[$row][$col] }[2] 					;
				# BACKGROUND COLOR			
				my $bg_color = ref $terrain{ $ui->{map}[$row][$col] }[3] eq 'ARRAY' ?
					$terrain{ $ui->{map}[$row][$col] }[3]->
						[int( rand( $#{$terrain{ $ui->{map}[$row][$col] }[3]}+1))]  :
							$terrain{ $ui->{map}[$row][$col] }[3]  					;
				
				# CHARCTER TO DISPLAY
				my $to_display = ref $terrain{ $ui->{map}[$row][$col] }[1] eq 'ARRAY' 	?
					$terrain{ $ui->{map}[$row][$col] }[1]->
						[int( rand( $#{$terrain{ $ui->{map}[$row][$col] }[1]}+1))]  	:
							$terrain{ $ui->{map}[$row][$col] }[1]  						;			
				
				# final tile is anonymous array
				$ui->{map}[$row][$col] = [
						$bg_color.$color.$to_display.RESET	, # 0 to display
						$ui->{map}[$row][$col]				, # 1 original letter of terrain
						$is_a_reload		?				  #   (if reloading conf
						$previous_unmasked	:                 # 	use old value of unamsked) 
						( $ui->{masked_map} ? 0 : 1)		, # 2 unmasked
				];
				
			}
			# letter not defined in %terrain final tile is anonymous array too
			else { print "WARNING: $ui->{map}[$row][$col] NOT FOUND IN TERRAINS!\n"; $ui->{map}[$row][$col]  =  [ $ui->{map}[$row][$col], $ui->{map}[$row][$col], 0]}
		}
	}
	# BEAUTIFY vertical decoration
	$ui->{ dec_ver } = 	$ui->{dec_color} 						?
						$ui->{dec_color}.$ui->{ dec_ver }.RESET :
						$ui->{ dec_ver } ;
	# BEAUTIFY horizontal decoration
	$ui->{ dec_hor } = 	$ui->{dec_color} 						?
						$ui->{dec_color}.$ui->{ dec_hor }.RESET :
						$ui->{ dec_hor } ;
	# BEAUTIFY external (fake) tiles
	$ui->{ ext_tile } = $ui->{dec_color} 						?
						$ui->{dec_color}.$ui->{ ext_tile }.RESET :
						$ui->{ ext_tile } ;
}
sub set_no_scrolling_area{
	my $ui = shift;
	
	if ( $ui->{no_scroll} == 0 ){
		if ( $ui->{hero_side} eq 'S' ){  
			$ui->{no_scroll_area}{min_x} = $ui->{hero}{x} - int($ui->{map_area_w} / 4);
			$ui->{no_scroll_area}{min_y} = $ui->{hero}{y} - int($ui->{map_area_h} / 2);
			
			$ui->{no_scroll_area}{max_y} = $ui->{hero}{y};
			$ui->{no_scroll_area}{max_x} = $ui->{hero}{x} + int($ui->{map_area_w} / 4);			
		}
		elsif ( $ui->{hero_side} eq 'N' ){ 
			$ui->{no_scroll_area}{min_x} = $ui->{hero}{x} - int($ui->{map_area_w} / 4);
			$ui->{no_scroll_area}{min_y} = $ui->{hero}{y}; 
			
			$ui->{no_scroll_area}{max_x} = $ui->{hero}{x} + int($ui->{map_area_w} / 4);
			$ui->{no_scroll_area}{max_y} = $ui->{hero}{y} + int($ui->{map_area_h} / 2);				
		}		
		elsif ( $ui->{hero_side} eq 'E' ){
			$ui->{no_scroll_area}{min_x} = $ui->{hero}{x} - int($ui->{map_area_w} / 2);
			$ui->{no_scroll_area}{min_y} = $ui->{hero}{y} - int($ui->{map_area_h} / 4);
			
			$ui->{no_scroll_area}{max_x} = $ui->{hero}{x} ;
			$ui->{no_scroll_area}{max_y} = $ui->{hero}{y} + int($ui->{map_area_h} / 4 );						
		}
		elsif ( $ui->{hero_side} eq 'W' ){
			$ui->{no_scroll_area}{min_x} = $ui->{hero}{x};
			$ui->{no_scroll_area}{min_y} = $ui->{hero}{y} - int($ui->{map_area_h} / 4);
			
			$ui->{no_scroll_area}{max_x} = $ui->{hero}{x} + int($ui->{map_area_w} / 2);
			$ui->{no_scroll_area}{max_y} = $ui->{hero}{y} + int($ui->{map_area_h} / 4);			
		}
		#
		elsif ( $ui->{hero_side} eq 'M' ){
				$ui->{scrolling} = 1;
		}
		else{die}
	}
	unless ( $ui->{hero_side} eq 'M' ){
		# FIX no_scroll_area inside map
		map {$_ = 0 if $_< 0} $ui->{no_scroll_area}{min_x},$ui->{no_scroll_area}{min_y};
		if ( $ui->{no_scroll_area}{max_y} > $#{$ui->{map}} ){
			$ui->{no_scroll_area}{max_y}=$#{$ui->{map}};
		}
		if ( $ui->{no_scroll_area}{max_x} > $#{$ui->{map}->[0]} ){
			$ui->{no_scroll_area}{max_x}=$#{$ui->{map}->[0]};
		}
		
		print "DEBUG: no_scroll area from $ui->{no_scroll_area}{min_y}-$ui->{no_scroll_area}{min_x} ",
				"to $ui->{no_scroll_area}{max_y}-$ui->{no_scroll_area}{max_x}\n" if $debug;
	}
	
}

sub set_hero_pos{
	my $ui = shift;
	# hero position MUST be on a side and NEVER on a corner
	print "DEBUG: original map size; rows: 0..",$#{$ui->{map}}," cols: 0..",$#{$ui->{map}->[0]}," \n" if $debug;
	foreach my $row ( 0..$#{$ui->{map}} ){
		foreach my $col ( 0..$#{$ui->{map}->[$row]} ){
			if ( 
					${$ui->{map}}[$row][$col] eq 'X' or
					( 
						ref ${$ui->{map}}[$row][$col] eq 'ARRAY' 
						and
						${$ui->{map}}[$row][$col][1] eq 'X'
					)
				){
				print "DEBUG: original map found hero at row $row col $col\n" if $debug;
				# clean this tile
				${$ui->{map}}[$row][$col] = 'd';
				$ui->{hero_y} = $row;
				$ui->{hero_x} = $col;
		#DOUBLE!!!!!!!!!!!
				$ui->{hero}{y} = $row;
				$ui->{hero}{x} = $col;
				
				if    ( $row == 0 )						{ $ui->{hero_side} = 'N' }
				elsif ( $row == $#{$ui->{map}} )		{ $ui->{hero_side} = 'S' }
				elsif ( $col == 0 )						{ $ui->{hero_side} = 'W' }
				elsif ( $col == $#{$ui->{map}->[$row]} ){ $ui->{hero_side} = 'E' }
				#else									{ die "Hero side not found!" }
				else									{ $ui->{hero_side} = 'M' }
			}				
		}
	}
	unless( defined $ui->{hero}{y} and defined $ui->{hero}{x}){die "Hero not found!"}
	
}

our %conv = (
			reset 	=>  RESET,	
			
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
			
			On_Black => ON_ANSI0,
			On_Maroon => ON_ANSI1,
			On_Green => ON_ANSI2,
			On_Olive => ON_ANSI3,
			On_Navy => ON_ANSI4,
			On_Purple => ON_ANSI5,
			On_Teal => ON_ANSI6,
			On_Silver => ON_ANSI7,
			On_Grey => ON_ANSI8,
			On_Red => ON_ANSI9,
			On_Lime => ON_ANSI10,
			On_Yellow => ON_ANSI11,
			On_Blue => ON_ANSI12,
			On_Fuchsia => ON_ANSI13,
			On_Aqua => ON_ANSI14,
			On_White => ON_ANSI15,
			On_Grey0 => ON_ANSI16,
			On_NavyBlue => ON_ANSI17,
			On_DarkBlue => ON_ANSI18,
			On_Blue3 => ON_ANSI19,
			On_Blue3 => ON_ANSI20,
			On_Blue1 => ON_ANSI21,
			On_DarkGreen => ON_ANSI22,
			On_DeepSkyBlue4 => ON_ANSI23,
			On_DeepSkyBlue4 => ON_ANSI24,
			On_DeepSkyBlue4 => ON_ANSI25,
			On_DodgerBlue3 => ON_ANSI26,
			On_DodgerBlue2 => ON_ANSI27,
			On_Green4 => ON_ANSI28,
			On_SpringGreen4 => ON_ANSI29,
			On_Turquoise4 => ON_ANSI30,
			On_DeepSkyBlue3 => ON_ANSI31,
			On_DeepSkyBlue3 => ON_ANSI32,
			On_DodgerBlue1 => ON_ANSI33,
			On_Green3 => ON_ANSI34,
			On_SpringGreen3 => ON_ANSI35,
			On_DarkCyan => ON_ANSI36,
			On_LightSeaGreen => ON_ANSI37,
			On_DeepSkyBlue2 => ON_ANSI38,
			On_DeepSkyBlue1 => ON_ANSI39,
			On_Green3 => ON_ANSI40,
			On_SpringGreen3 => ON_ANSI41,
			On_SpringGreen2 => ON_ANSI42,
			On_Cyan3 => ON_ANSI43,
			On_DarkTurquoise => ON_ANSI44,
			On_Turquoise2 => ON_ANSI45,
			On_Green1 => ON_ANSI46,
			On_SpringGreen2 => ON_ANSI47,
			On_SpringGreen1 => ON_ANSI48,
			On_MediumSpringGreen => ON_ANSI49,
			On_Cyan2 => ON_ANSI50,
			On_Cyan1 => ON_ANSI51,
			On_DarkRed => ON_ANSI52,
			On_DeepPink4 => ON_ANSI53,
			On_Purple4 => ON_ANSI54,
			On_Purple4 => ON_ANSI55,
			On_Purple3 => ON_ANSI56,
			On_BlueViolet => ON_ANSI57,
			On_Orange4 => ON_ANSI58,
			On_Grey37 => ON_ANSI59,
			On_MediumPurple4 => ON_ANSI60,
			On_SlateBlue3 => ON_ANSI61,
			On_SlateBlue3 => ON_ANSI62,
			On_RoyalBlue1 => ON_ANSI63,
			On_Chartreuse4 => ON_ANSI64,
			On_DarkSeaGreen4 => ON_ANSI65,
			On_PaleTurquoise4 => ON_ANSI66,
			On_SteelBlue => ON_ANSI67,
			On_SteelBlue3 => ON_ANSI68,
			On_CornflowerBlue => ON_ANSI69,
			On_Chartreuse3 => ON_ANSI70,
			On_DarkSeaGreen4 => ON_ANSI71,
			On_CadetBlue => ON_ANSI72,
			On_CadetBlue => ON_ANSI73,
			On_SkyBlue3 => ON_ANSI74,
			On_SteelBlue1 => ON_ANSI75,
			On_Chartreuse3 => ON_ANSI76,
			On_PaleGreen3 => ON_ANSI77,
			On_SeaGreen3 => ON_ANSI78,
			On_Aquamarine3 => ON_ANSI79,
			On_MediumTurquoise => ON_ANSI80,
			On_SteelBlue1 => ON_ANSI81,
			On_Chartreuse2 => ON_ANSI82,
			On_SeaGreen2 => ON_ANSI83,
			On_SeaGreen1 => ON_ANSI84,
			On_SeaGreen1 => ON_ANSI85,
			On_Aquamarine1 => ON_ANSI86,
			On_DarkSlateGray2 => ON_ANSI87,
			On_DarkRed => ON_ANSI88,
			On_DeepPink4 => ON_ANSI89,
			On_DarkMagenta => ON_ANSI90,
			On_DarkMagenta => ON_ANSI91,
			On_DarkViolet => ON_ANSI92,
			On_Purple => ON_ANSI93,
			On_Orange4 => ON_ANSI94,
			On_LightPink4 => ON_ANSI95,
			On_Plum4 => ON_ANSI96,
			On_MediumPurple3 => ON_ANSI97,
			On_MediumPurple3 => ON_ANSI98,
			On_SlateBlue1 => ON_ANSI99,
			On_Yellow4 => ON_ANSI100,
			On_Wheat4 => ON_ANSI101,
			On_Grey53 => ON_ANSI102,
			On_LightSlateGrey => ON_ANSI103,
			On_MediumPurple => ON_ANSI104,
			On_LightSlateBlue => ON_ANSI105,
			On_Yellow4 => ON_ANSI106,
			On_DarkOliveGreen3 => ON_ANSI107,
			On_DarkSeaGreen => ON_ANSI108,
			On_LightSkyBlue3 => ON_ANSI109,
			On_LightSkyBlue3 => ON_ANSI110,
			On_SkyBlue2 => ON_ANSI111,
			On_Chartreuse2 => ON_ANSI112,
			On_DarkOliveGreen3 => ON_ANSI113,
			On_PaleGreen3 => ON_ANSI114,
			On_DarkSeaGreen3 => ON_ANSI115,
			On_DarkSlateGray3 => ON_ANSI116,
			On_SkyBlue1 => ON_ANSI117,
			On_Chartreuse1 => ON_ANSI118,
			On_LightGreen => ON_ANSI119,
			On_LightGreen => ON_ANSI120,
			On_PaleGreen1 => ON_ANSI121,
			On_Aquamarine1 => ON_ANSI122,
			On_DarkSlateGray1 => ON_ANSI123,
			On_Red3 => ON_ANSI124,
			On_DeepPink4 => ON_ANSI125,
			On_MediumVioletRed => ON_ANSI126,
			On_Magenta3 => ON_ANSI127,
			On_DarkViolet => ON_ANSI128,
			On_Purple => ON_ANSI129,
			On_DarkOrange3 => ON_ANSI130,
			On_IndianRed => ON_ANSI131,
			On_HotPink3 => ON_ANSI132,
			On_MediumOrchid3 => ON_ANSI133,
			On_MediumOrchid => ON_ANSI134,
			On_MediumPurple2 => ON_ANSI135,
			On_DarkGoldenrod => ON_ANSI136,
			On_LightSalmon3 => ON_ANSI137,
			On_RosyBrown => ON_ANSI138,
			On_Grey63 => ON_ANSI139,
			On_MediumPurple2 => ON_ANSI140,
			On_MediumPurple1 => ON_ANSI141,
			On_Gold3 => ON_ANSI142,
			On_DarkKhaki => ON_ANSI143,
			On_NavajoWhite3 => ON_ANSI144,
			On_Grey69 => ON_ANSI145,
			On_LightSteelBlue3 => ON_ANSI146,
			On_LightSteelBlue => ON_ANSI147,
			On_Yellow3 => ON_ANSI148,
			On_DarkOliveGreen3 => ON_ANSI149,
			On_DarkSeaGreen3 => ON_ANSI150,
			On_DarkSeaGreen2 => ON_ANSI151,
			On_LightCyan3 => ON_ANSI152,
			On_LightSkyBlue1 => ON_ANSI153,
			On_GreenYellow => ON_ANSI154,
			On_DarkOliveGreen2 => ON_ANSI155,
			On_PaleGreen1 => ON_ANSI156,
			On_DarkSeaGreen2 => ON_ANSI157,
			On_DarkSeaGreen1 => ON_ANSI158,
			On_PaleTurquoise1 => ON_ANSI159,
			On_Red3 => ON_ANSI160,
			On_DeepPink3 => ON_ANSI161,
			On_DeepPink3 => ON_ANSI162,
			On_Magenta3 => ON_ANSI163,
			On_Magenta3 => ON_ANSI164,
			On_Magenta2 => ON_ANSI165,
			On_DarkOrange3 => ON_ANSI166,
			On_IndianRed => ON_ANSI167,
			On_HotPink3 => ON_ANSI168,
			On_HotPink2 => ON_ANSI169,
			On_Orchid => ON_ANSI170,
			On_MediumOrchid1 => ON_ANSI171,
			On_Orange3 => ON_ANSI172,
			On_LightSalmon3 => ON_ANSI173,
			On_LightPink3 => ON_ANSI174,
			On_Pink3 => ON_ANSI175,
			On_Plum3 => ON_ANSI176,
			On_Violet => ON_ANSI177,
			On_Gold3 => ON_ANSI178,
			On_LightGoldenrod3 => ON_ANSI179,
			On_Tan => ON_ANSI180,
			On_MistyRose3 => ON_ANSI181,
			On_Thistle3 => ON_ANSI182,
			On_Plum2 => ON_ANSI183,
			On_Yellow3 => ON_ANSI184,
			On_Khaki3 => ON_ANSI185,
			On_LightGoldenrod2 => ON_ANSI186,
			On_LightYellow3 => ON_ANSI187,
			On_Grey84 => ON_ANSI188,
			On_LightSteelBlue1 => ON_ANSI189,
			On_Yellow2 => ON_ANSI190,
			On_DarkOliveGreen1 => ON_ANSI191,
			On_DarkOliveGreen1 => ON_ANSI192,
			On_DarkSeaGreen1 => ON_ANSI193,
			On_Honeydew2 => ON_ANSI194,
			On_LightCyan1 => ON_ANSI195,
			On_Red1 => ON_ANSI196,
			On_DeepPink2 => ON_ANSI197,
			On_DeepPink1 => ON_ANSI198,
			On_DeepPink1 => ON_ANSI199,
			On_Magenta2 => ON_ANSI200,
			On_Magenta1 => ON_ANSI201,
			On_OrangeRed1 => ON_ANSI202,
			On_IndianRed1 => ON_ANSI203,
			On_IndianRed1 => ON_ANSI204,
			On_HotPink => ON_ANSI205,
			On_HotPink => ON_ANSI206,
			On_MediumOrchid1 => ON_ANSI207,
			On_DarkOrange => ON_ANSI208,
			On_Salmon1 => ON_ANSI209,
			On_LightCoral => ON_ANSI210,
			On_PaleVioletRed1 => ON_ANSI211,
			On_Orchid2 => ON_ANSI212,
			On_Orchid1 => ON_ANSI213,
			On_Orange1 => ON_ANSI214,
			On_SandyBrown => ON_ANSI215,
			On_LightSalmon1 => ON_ANSI216,
			On_LightPink1 => ON_ANSI217,
			On_Pink1 => ON_ANSI218,
			On_Plum1 => ON_ANSI219,
			On_Gold1 => ON_ANSI220,
			On_LightGoldenrod2 => ON_ANSI221,
			On_LightGoldenrod2 => ON_ANSI222,
			On_NavajoWhite1 => ON_ANSI223,
			On_MistyRose1 => ON_ANSI224,
			On_Thistle1 => ON_ANSI225,
			On_Yellow1 => ON_ANSI226,
			On_LightGoldenrod1 => ON_ANSI227,
			On_Khaki1 => ON_ANSI228,
			On_Wheat1 => ON_ANSI229,
			On_Cornsilk1 => ON_ANSI230,
			On_Grey100 => ON_ANSI231,
			On_Grey3 => ON_ANSI232,
			On_Grey7 => ON_ANSI233,
			On_Grey11 => ON_ANSI234,
			On_Grey15 => ON_ANSI235,
			On_Grey19 => ON_ANSI236,
			On_Grey23 => ON_ANSI237,
			On_Grey27 => ON_ANSI238,
			On_Grey30 => ON_ANSI239,
			On_Grey35 => ON_ANSI240,
			On_Grey39 => ON_ANSI241,
			On_Grey42 => ON_ANSI242,
			On_Grey46 => ON_ANSI243,
			On_Grey50 => ON_ANSI244,
			On_Grey54 => ON_ANSI245,
			On_Grey58 => ON_ANSI246,
			On_Grey62 => ON_ANSI247,
			On_Grey66 => ON_ANSI248,
			On_Grey70 => ON_ANSI249,
			On_Grey74 => ON_ANSI250,
			On_Grey78 => ON_ANSI251,
			On_Grey82 => ON_ANSI252,
			On_Grey85 => ON_ANSI253,
			On_Grey89 => ON_ANSI254,
			On_Grey93 => ON_ANSI255,
);

sub color_names_to_ANSI {
	my $ui = shift;
	return '' unless $_[0] and exists $conv{$_[0]};
	if(exists $conv{$_[0]}){ return $conv{$_[0]} }
	# elsif( $_[0] eq '' ){return ''}
	else{carp "'$conv{$_[0]}' is not a valid ANSI color name!"}
}

1; # End of Game::Term::UI
__DATA__

see also Graph::Weighted
https://metacpan.org/pod/Game::PlatformsOfPeril


useful article linked by simcop2387 https://www.redblobgames.com/
	and https://www.reddit.com/r/gamedev/
	https://opengameart.org/
	FONTS: https://opengameart.org/art-search-advanced?keys=&title=&field_art_tags_tid_op=or&field_art_tags_tid=font%2C%20fonts&name=&field_art_type_tid[9]=9&field_art_type_tid[10]=10&field_art_type_tid[7273]=7273&field_art_type_tid[14]=14&field_art_type_tid[12]=12&field_art_type_tid[13]=13&field_art_type_tid[11]=11&field_art_licenses_tid[17981]=17981&field_art_licenses_tid[2]=2&field_art_licenses_tid[17982]=17982&field_art_licenses_tid[3]=3&field_art_licenses_tid[6]=6&field_art_licenses_tid[5]=5&field_art_licenses_tid[10310]=10310&field_art_licenses_tid[4]=4&field_art_licenses_tid[8]=8&field_art_licenses_tid[7]=7&sort_by=score&sort_order=DESC&items_per_page=24&collection=

useful article linked by Corion: 
	http://journal.stuffwithstuff.com/2014/07/15/a-turn-based-game-loop/
	http://gameprogrammingpatterns.com/command.html
	http://gameprogrammingpatterns.com/event-queue.html
	http://gameprogrammingpatterns.com/observer.html
	
	
ECS:	
	https://en.wikipedia.org/wiki/Entity_component_system

color tool https://devblogs.microsoft.com/commandline/introducing-the-windows-console-colortool/

  ▲ ▲
  █_█
 ▄█_█▄
 
  ▲ 
  █_▲
 ▄█_█▄
 
  ▲ 
  █▄
       |>
      / \
      |o|
  .-.-.-.-.
  |_|#|_|_|
  

# on Windows10 :constants256 works
# on Windows 7 no. But:
# a) from cmd.exe launch ansicon.exe will enable colors (but UNDERLINE and UNDERSCORE will not work)
#                        https://github.com/adoxa/ansicon/releases
# anyway underline does not work and no 256 are displayed but 16

# b) MobaXterm will not work
# c) cmder_mini (OK WITH ULISSE!) has not full color support
# d) cmder (OK WITH ULISSE!) has not full color support
# e) powercmd (no ulisse) no colors no readkey!
# f) conemu (no ulisse) no exetended colors
# g) ???? mintty has full support.. https://mintty.github.io/
#         https://code.google.com/archive/p/mintty/downloads
# h) terminus (no ulisse support)

https://superuser.com/questions/413073/windows-console-with-ansi-colors-handling

# perl -I .\lib -MGame::Term::UI -MData::Dump -e "$ui=Game::Term::UI->new(); print $ui->{map_area_w}.$/;dd $ui; dd $ui->{map};$ui->run"
# perl -I .\lib -MGame::Term::UI -MData::Dump -e "$ui=Game::Term::UI->new();$ui->run"


		perl -I .\lib -MGame::Term::UI -e "$ui=Game::Term::UI->new();$ui->run"
		perl -I .\lib -MGame::Term::UI -e "Game::Term::UI->new()->run"

		
perl -e "print qq(\e[31mCOLORED\e[0m)"

perl -E "print qq(\e[$_),'m',qq( $_ ),qq(\e[0m) for 4..7,31..36,41..47"


## COLORS NAMES
https://jonasjacek.github.io/colors/

## COLORS cmd.exe INFOS
http://www.bribes.org/perl/wANSIConsole.html

## ASCII MAPPER
https://notimetoplay.itch.io/ascii-mapper

## FONT FORGE
https://www.elegantthemes.com/blog/tips-tricks/create-your-own-font
https://www.gridsagegames.com/blog/2014/09/fonts-in-roguelikes/
http://www.medievia.com/fonts.html
telnet mapscii.me
http://dwarffortresswiki.org/Tileset_repository  cheepicus_15x15   	Belal 
-->> http://dffd.bay12games.com/file.php?id=1922
https://int10h.org/oldschool-pc-fonts/fontlist/
---> http://www.pentacom.jp/pentacom/bitfontmaker2/  funziona LucidaConsoleaa.ttf
--> but: https://superuser.com/questions/920440/how-to-add-additional-fonts-to-the-windows-console-windows
https://github.com/powerline/fonts

how to install a font for cmd.exe https://www.techrepublic.com/blog/windows-and-office/quick-tip-add-fonts-to-the-command-prompt/
https://www.windowsperl.com/2014/04/25/the-command-prompt-and-fonts/
raster fonts ?? https://github.com/idispatch/raster-fonts	

https://www.thefreewindows.com/3467/edit-your-fonts-with-fony/ fony.exe mmh.. no ttf


---> https://fonts.google.com/?category=Monospace


perl -we "use strict; use warnings; use Term::ANSIColor qw(:constants); my %colors = (B_GREEN => $^O eq 'MSWin32' ? BOLD GREEN : BRIGHT_GREEN); my $bg = ON_GREEN; print $bg.$colors{B_GREEN}, 32323, RESET"
perl -e "use Term::ANSIColor qw(:constants); $B_GREEN = $^O eq 'Linux' ? BRIGHT_GREEN : BOLD GREEN; print $B_GREEN, 32323, RESET"

perl -we "use strict; use warnings; use Term::ANSIColor 4.00 qw(RESET :constants :constants256); my %colors = (B_GREEN => $^O eq 'MSWin32' ? ANSI123: BRIGHT_GREEN); my $bg = ON_RED; print UNDERLINE.$bg.$colors{B_GREEN}, 32323, RESET"

perl -we "use strict; use warnings; use Term::ANSIColor 4.00 qw(RESET :constants :constants256); my %colors = (B_GREEN => $^O eq 'MSWin32' ? ANSI27: BRIGHT_GREEN); my $bg = ''; print UNDERLINE.$bg.$colors{B_GREEN}, 32323, RESET"

https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences/33206814

colortools\ColorTool.exe  -c

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




=head1 ABOUT COLORS 

The module uses L<Term::ANSIColor> to manage colors. Specifically L<Term::ANSIColor> version 4.06 can export some constant to represent ANSI colors from 0 to 255. Unfortunately not all consoles are able to display them correctly. 

Many consoles and notably C<cmd.exe> are bound to 16 colors. The present module tries to make possible to use the more appropriate color palette depending on the system you are running the code.

To make things more complex some C<ANSI> sequence is interpreted differently or misinterpreted or even ignored on some console. 

The current module uses the full constant interface provided by  L<Term::ANSIColor> version 4.06 with some minimal addition in the aim of offer a standard way to display the same color in every console. 

So if you are on a full 256 colors console you can use the whole spectrum of constants exported by L<Term::ANSIColor> and probably everything will run as expected.    



=head3 ADDITIONS TO THE STANDARD SET OF COLOR CONSTANTS

ANSI sequences ( used as exported by L<Term::ANSIColor> constants interface) can specify a given color but also a modification as C<BOLD> or C<UNDERLINE> or even action like C<RESET>. The standard way to specify a brighter color (in the set of 16 basic ones) is C<BRIGHT_RED> that will result into a brighter C<RED>. While this is expected to work correctly on Linux will fail on Windows (prior to Windows10: more on this after).

Windows historically misuses C<BOLD> to render a brighter color. So you need to use different syntax to have the same bright red rendered:

		use Term::ANSIColor 4.00 qw(RESET :constants); 
		
		print BRIGHT_RED, 3333, RESET;  # bright red on Linux
		print BOLD RED, 3333, RESET;    # bright red on Windows


I workarounded this nasty situation defining inside the my module 8 constant more:

		B_BLACK  B_RED      B_GREEN   B_YELLOW  
		B_BLUE   B_MAGENTA  B_CYAN    B_WHITE
		
These 8 constants will be the right thing on both Windows and Linux:

		print B_RED, 3333, RESET;    # bright red on Windows and Linux


		
=head3 RECAP OF 16 COLORS TO USE TO WRITE MORE PORTABLE GAMES
		
	# darker colors				# brigther colors

	ANSI0  Black (SYSTEM)		ANSI8  Grey (SYSTEM)
	ANSI1  Maroon (SYSTEM)		ANSI9  Red (SYSTEM)
	ANSI2  Green (SYSTEM)		ANSI10  Lime (SYSTEM)
	ANSI3  Olive (SYSTEM)		ANSI11  Yellow (SYSTEM)
	ANSI4  Navy (SYSTEM)		ANSI12  Blue (SYSTEM)
	ANSI5  Purple (SYSTEM)		ANSI13  Fuchsia (SYSTEM)
	ANSI6  Teal (SYSTEM)		ANSI14  Aqua (SYSTEM)
	ANSI7  Silver (SYSTEM)		ANSI15  White (SYSTEM)




=HEAD3 MORE COLOR PROBLEMS ON OLDER WINDOWS

With Windows10 finally C<cmd.exe> can use 256 colors ( perhaps you need to enable this feature) but older versions  still cannot. Also alternative consoles available for Windows seems to be unable to render. The only useful thing I found during my investigation is L<https://github.com/adoxa/ansicon|ansicon> that launched into a 16 color C<cmd.exe> window will enable a more correct interpretation of ANSI sequences:  for example C<BRIGHT_RED> will work as expected. Visit L<https://github.com/adoxa/ansicon/releases> to get the latest C<ansicon.exe> release. 
Thanks to Jason Hood for his work.

More interestingly after using C<ansicon.exe> all L<Term::ANSIColor> newer constants from C<ANSI0> to C<ANSI255> will produce the more appropriate color choosen in the 16 color available.

=head3 color_names.pl

This distribution ships with the program C<color_names.pl> that prints the entire 256 colors palette from C<ANSI0> to C<ANSI255> with names of colors.

 
		
		
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


