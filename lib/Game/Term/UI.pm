package Game::Term::UI;

use 5.014;
use strict;
use warnings;
use Term::ReadKey;
use List::Util qw( max min );
use Term::ANSIColor qw(RESET :constants :constants256);
use Time::HiRes qw ( sleep );

use Game::Term::Configuration;
use Game::Term::Map;

ReadMode 'cbreak';

our $VERSION = '0.01';

our $debug = 0;
our $noscroll_debug = 0;

# SOME NOTES ABOUT MAP:
# The map is initially loaded from the data field of the Game::Term::Map object.
# It is the AoA containing one character per tile (terrains) and containing the hero's
# starting position marked by 'X' ( sticked on one side ).

# This original AoA is passed to set_map_and_hero() where it will be enlarged depending
# on the map_area settings (the display window). Here the offsets used in print will be calculated.

# Then beautify_map() will modify tiles of the map using colors and deciding which character to use
# when display the map. Tiles of the map will also be transformed into anonymous arrays to hold other
# types of informations.

# Each tile will end to be:  [ 0:to_display,  1:original_terrain_letter,  2:unmasked ]

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


my %terrain;


sub new{
	my $class = shift;
	my %params = @_;
	
	# CONFIGURATION:
	my $conf_object = Game::Term::Configuration->new( configuration => $params{configuration});
	my %conf = $conf_object->get_conf();
	# OTHER FIELDS USED INTERNALLY (once set by validate_conf)
	# # set internally to get coord of the first element of the map
	# $conf{ real_map_first} = { x => undef, y => undef };
	# # set internally to get coord of the last element of the map
	# $conf{ real_map_last} = { x => undef, y => undef };
	# $conf{ cls_cmd }     //= $^O eq 'MSWin32' ? 'cls' : 'clear';
	# # get and set internally
	# $conf{ hero_x } = undef;
	# $conf{ hero_y } = undef;
	# $conf{ hero_side } = '';
	# $conf{ hero_terrain } = ''; #new!
	# # get and set internally
	# $conf{ map } //=[];
	# $conf{ map_off_x } = 0;
	# $conf{ map_off_y } = 0;
	# $conf{ scrolling } = 0;
	# $conf{ no_scroll_area} = { min_x=>'',max_x=>'',min_y=>'',max_y=>'' };	
	#my %conf = validate_conf( @_ );
	
	
	%terrain = $conf_object->get_terrains();
	
	return bless {
				%conf
	}, $class;
}

sub run{
		my $ui = shift;
		
		my $map = Game::Term::Map->new(  );
		print map{ join'',@$_,$/ } @{$map->{data}} if $debug > 1;
		$ui->{map} = $map->{data};
		
		# enlarge the map to be scrollable
		# set the hero's coordinates
		# set real_map_first and real_map_last x,y
		$ui->set_map_and_hero();
		
		print "DEBUG: real map corners(x-y): $ui->{real_map_first}{x}-$ui->{real_map_first}{y}",
				" $ui->{real_map_last}{x}-$ui->{real_map_first}{y}\n" if $debug;
		# now BIG map, hero_pos and hero_side are initialized
		# time to generate offsets for print: map_off_x and map_off_y (and the no_scroll region..)		
		
		print "DEBUG: NEW MAP: rows 0 - $#{$ui->{map}} columns 0 - $#{$ui->{ map }[0]}\n" if $debug;
			
		$ui->set_map_offsets();
	
		$ui->draw_map();
		$ui->draw_menu( ["hero HP: 42","walk with WASD"] );	
		while(1){
			my $key = ReadKey(0);
			
			sleep(	
					$ui->{hero_slowness} + 
					# the slowness #4 of the terrain original letter #1 where
					# the hero currently is on th emap
					$terrain{$ui->{map}->[ $ui->{hero_y} ][ $ui->{hero_x} ]->[1]}->[4]
			);
			print "DEBUG: slowness for terrain ".
				$terrain{$ui->{map}->[ $ui->{hero_y} ][ $ui->{hero_x} ]->[1]}->[4].
				"\n" if $debug;
			if( $ui->move( $key ) ){
				local $ui->{hero_sight} = $ui->{hero_sight} + 2 if $ui->{hero_terrain} eq 'hill';
				local $ui->{hero_sight} = $ui->{hero_sight} + 4 if $ui->{hero_terrain} eq 'mountain';
				local $ui->{hero_sight} = $ui->{hero_sight} - 2 if $ui->{hero_terrain} eq 'wood';
				$ui->draw_map();
				
		if ($noscroll_debug){
		 $ui->{map}->[$ui->{no_scroll_area}{min_y}][$ui->{no_scroll_area}{min_x}] = ['+','+',1];
		 $ui->{map}->[$ui->{no_scroll_area}{max_y}][$ui->{no_scroll_area}{max_x}] = ['+','+',1];
		 #print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n";
		 print 	"MAP SIZE: rows: 0..",$#{$ui->{map}}," cols: 0..",$#{$ui->{map}->[0]}," \n",
				"NOSCROLL corners: $ui->{no_scroll_area}{min_y}-$ui->{no_scroll_area}{min_x} ",
				"$ui->{no_scroll_area}{max_y}-$ui->{no_scroll_area}{max_x}\n";
		 print "OFF_Y used in print: $ui->{map_off_y} .. $ui->{map_off_y} + $ui->{map_area_h}\n";
		 print "OFF_X used in print: ($ui->{map_off_x} + 1) .. ($ui->{map_off_x} + $ui->{map_area_w})\n";
	}
			
			$ui->draw_menu( ["hero at: $ui->{hero_y}-$ui->{hero_x} ".
								"( $ui->{hero_terrain} ) sight: $ui->{hero_sight} ".
								"slowness: ".
								($ui->{hero_slowness} + 
								$terrain{$ui->{map}->[ $ui->{hero_y} ][ $ui->{hero_x} ]->[1]}->[4]),
									"key $key was pressed:"] );	

			}
			print "DEBUG: hero_x => $ui->{hero_x} hero_y $ui->{hero_y}\n" if $debug;		
		
		}
}

sub set_map_offsets{
	my $ui = shift;	
	if ( $ui->{hero_side} eq 'S' ){		
		$ui->{map_off_x} =  $ui->{hero_x} - $ui->{map_area_w} / 2; 
		$ui->{map_off_y} =  $ui->{hero_y} - $ui->{map_area_h} ;		
		print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n" if $debug;
	}
	elsif ( $ui->{hero_side} eq 'N' ){		
		$ui->{map_off_x} =  $ui->{hero_x} - $ui->{map_area_w} / 2;
		$ui->{map_off_y} =  $ui->{hero_y}   ;		
		print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n" if $debug;
	}
	elsif ( $ui->{hero_side} eq 'E' ){		
		$ui->{map_off_x} = $ui->{hero_x} - $ui->{map_area_w} ;
		$ui->{map_off_y} =  $ui->{hero_y} - $ui->{map_area_h} / 2; # ok ma no ... f di hero.. $ui->{map_area_h} + 1;
		print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n" if $debug;
	}	
	elsif ( $ui->{hero_side} eq 'W' ){		
		$ui->{map_off_x} = $ui->{hero_x} - 1; # ???? 
		$ui->{map_off_y} = $ui->{hero_y} - $ui->{map_area_h} / 2;		
		print "DEBUG: map print offsets: x =  $ui->{map_off_x} y = $ui->{map_off_y}\n" if $debug;
	}
	else{die}

}
sub draw_map{
	my $ui = shift;
	# clear screen
	system $ui->{ cls_cmd } unless $debug;
	#print CLEAR unless $debug;
	# get area of currently seen tiles (by coords)
	my %seen = $ui->illuminate();
	
	# draw hero
	# this must set $hero->{on_terrain}
	local $ui->{map}[ $ui->{hero_y} ][ $ui->{hero_x} ] = $ui->{hero_icon}; 
	# MAP AREA:
	# print decoration first row
	if ($ui->{dec_color}){
		print $ui->{dec_color}.(' o'.($ui->{ dec_hor } x  $ui->{ map_area_w }  )).'o'.RESET."\n";
	}
	else { print ' o',$ui->{ dec_hor } x ( $ui->{ map_area_w } ), 'o',"\n";} 
	# print map body with decorations
	# iterate indexes of rows..
	foreach my $row ( $ui->{map_off_y}..$ui->{map_off_y} + $ui->{map_area_h}   ){ 	
				# print decoration vertical
				print ' ',	($ui->{dec_color} 						?
							$ui->{dec_color}.$ui->{ dec_ver }.RESET :
							$ui->{ dec_ver } );
				
				# iterate cols by indexes 
				foreach my $col  ( $ui->{map_off_x} + 1 ..$ui->{map_off_x} + $ui->{map_area_w}  ){
					# if is seen (in the radius of illuminate) and still masked
					if ( $seen{$row.'_'.$col} and $ui->{map}[$row][$col][2] == 0 ){
						# set unmasked
						$ui->{map}[$row][$col][2] = 1;
						# print display
						print $ui->{map}[$row][$col][0];					
					}
					# already unmasked but empty space (fog of war)
					elsif( 	$ui->{map}[$row][$col][2] == 1 		and 
							$ui->{map}[$row][$col][1] eq ' ' 	and # WITH [0]FAILS!!!!!
							$ui->{fog_of_war}					and
							!$seen{$row.'_'.$col}
						)
					{ 
						print $ui->{fog_char} ;
					}
					# already unmasked: print display 
					elsif( $ui->{map}[$row][$col][2] == 1 ){ print $ui->{map}[$row][$col][0]; }
					# print ' ' if still masked
					else{ print ' '}
				}
				# print decoration vertical and newline
				#print $ui->{ dec_ver },"\n";
				print +($ui->{dec_color} 						?
							$ui->{dec_color}.$ui->{ dec_ver }.RESET :
							$ui->{ dec_ver }),"\n" ;
	}	
	# print decoration last row
	#print ' o',$ui->{ dec_hor } x ($ui-> { map_area_w }), 'o',"\n";
	# print  	$ui->{dec_color} 																	? 
			# $ui->{dec_color}.(' o'.($ui->{ dec_hor } x ( $ui->{ map_area_w } ))).'o'."\n".RESET 	:
			# ' o',$ui->{ dec_hor } x ( $ui->{ map_area_w } ), 'o',"\n";
	if ($ui->{dec_color}){
		print $ui->{dec_color}.(' o'.($ui->{ dec_hor } x  $ui->{ map_area_w }  )).'o'.RESET."\n";
	}
	else { print ' o',$ui->{ dec_hor } x ( $ui->{ map_area_w } ), 'o',"\n";}
	
}

sub move{
	my $ui = shift;
	my $key = shift;
	
	# move with WASD
	if ( $key eq 'w' 	
		# we are inside the real map
		and $ui->{hero_y} > $ui->{real_map_first}{y} 
		and  is_walkable(
			# map coord as hero X - 1, hero Y
			$ui->{map}->[ $ui->{hero_y} - 1 ][	$ui->{hero_x} ]
			)
					
		){
        #									THIS must be set to $hero->{on_terrain}
		$ui->{hero_y}--;
		$ui->{map_off_y}-- if $ui->must_scroll();
        #                     el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
		$ui->{hero_terrain} = $terrain{$ui->{map}->[ $ui->{hero_y} ][ $ui->{hero_x} ]->[1]  }->[0];
		return 1;
    }
	elsif ( $key eq 's'
			# we are inside the real map
			and $ui->{hero_y} < $ui->{real_map_last}{y} - 1
			and  is_walkable(
						# map coord as hero X + 1, hero Y
						$ui->{map}->[ $ui->{hero_y} + 1 ][	$ui->{hero_x} ]
						)
		){
        #									THIS must be set to $hero->{on_terrain}
		$ui->{hero_y}++;
		$ui->{map_off_y}++ if $ui->must_scroll();		
        #                     el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
		$ui->{hero_terrain} = $terrain{$ui->{map}->[ $ui->{hero_y} ][ $ui->{hero_x} ]->[1]  }->[0];
		return 1;
    }
	elsif ( $key eq 'a' 
			# we are inside the real map
			and $ui->{hero_x} > $ui->{real_map_first}{x}
			and  is_walkable(
							# map coord as hero X, hero Y - 1
							$ui->{map}->[ $ui->{hero_y} ][	$ui->{hero_x} - 1 ]
							)
		){
        #									THIS must be set to $hero->{on_terrain}
		$ui->{hero_x}--;
		$ui->{map_off_x}-- if $ui->must_scroll();		
        #                     el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
		$ui->{hero_terrain} = $terrain{$ui->{map}->[ $ui->{hero_y} ][ $ui->{hero_x} ]->[1]  }->[0];
		return 1;
    }
	elsif ( $key eq 'd' 
			# we are inside the real map
			and $ui->{hero_x} < $ui->{real_map_last}{x}
			and  is_walkable(
							# map coord as hero X, hero Y + 1
							$ui->{map}->[ $ui->{hero_y} ][	$ui->{hero_x} + 1 ]
							)
		){
        #									THIS must be set to $hero->{on_terrain}
		$ui->{hero_x}++;
		$ui->{map_off_x}++ if $ui->must_scroll();				
        #                     el. #0 (descr) of the terrain on which the hero is on the map (el. #1 original chr)
		$ui->{hero_terrain} = $terrain{$ui->{map}->[ $ui->{hero_y} ][ $ui->{hero_x} ]->[1]  }->[0];
		return 1;
    }
	else{
		print "DEBUG: no movement possible ([$key] was pressed)\n" if $debug;
		return 0;
	}
	
}

sub must_scroll{
	my $ui = shift;
	return 0 if $ui->{no_scroll};
	return 1 if $ui->{scrolling};
	if(	 
		$ui->{hero_y} < $ui->{no_scroll_area}{min_y} or
		$ui->{hero_y} > $ui->{no_scroll_area}{max_y} or
		$ui->{hero_x} < $ui->{no_scroll_area}{min_x} or
		$ui->{hero_x} > $ui->{no_scroll_area}{max_x} #and $ui->{scrolling} == 0
	
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
	
	foreach my $row ( $ui->{hero_y} - $ui->{hero_sight}  .. $ui->{hero_y}  + $ui->{hero_sight} ){
		my $delta_x = $ui->{hero_sight} ** 2 - ($ui->{hero_y} - $row) ** 2;
		if( $delta_x >= 0 ){				
				$delta_x = int sqrt $delta_x;			
				my $low = max 0, $ui->{hero_x} - $delta_x;
				my $high = min $#{ $ui->{map}->[$row] }, $ui->{hero_x} + $delta_x;
				map { $ret{ $row.'_'.$_ }++ } $low .. $high;				
		}
	}
	   return %ret;
}
sub is_walkable{
	my $tile = shift; 
	# if( $tile->[1] eq ' ' ){ return 1 }
	# elsif( $tile->[1] eq '+' ){ return 1 }
	#print "DEBUG: tile -->",(join '|',@$tile),"<--\n";
	
	if ( $terrain{ $tile->[1]}->[4] < 5 ){ return 1}
	else{return 0}
}
		
sub draw_menu{
	my $ui = shift;
	my $messages = shift;
	# MENU AREA:
	# print decoration first row
	#print ' o',$ui->{ dec_hor } x ($ui-> { map_area_w }), 'o',"\n";
	if ($ui->{dec_color}){
		print $ui->{dec_color}.(' o'.($ui->{ dec_hor } x  $ui->{ map_area_w }  )).'o'.RESET."\n";
	}
	else { print ' o',$ui->{ dec_hor } x ( $ui->{ map_area_w } ), 'o',"\n";}
	# menu fake data
	print ' ',$ui->{dec_color}.$ui->{ dec_ver }.RESET.$_."\n" for @$messages;
}

sub set_map_and_hero{
	my $ui = shift;

	my $original_map_w = $#{$ui->{map}->[0]} + 1;
	my $original_map_h = $#{$ui->{map}} + 1;
	print "DEBUG: origial map was $original_map_w x $original_map_h\n" if $debug;
	# get hero position and side BEFORE enlarging
	$ui->set_hero_pos();
	# change external tile to []
	$ui->{ ext_tile } = [ 
							(
								$ui->{dec_color} 							?
								$ui->{dec_color}.$ui->{ ext_tile }.RESET 	:
								$ui->{ ext_tile }
							), 
							$ui->{ ext_tile },
							1	# unmasked
						];
	# change hero icon to []
	$ui->{ hero_icon } = [ $ui->{ hero_color }.$ui->{ hero_icon }.RESET, $ui->{ hero_icon }, 1 ];
	# add at top
	my @map = map { [ ($ui->{ ext_tile }) x ( $original_map_w + $ui->{ map_area_w } * 2 ) ]} 0..$ui->{ map_area_h } ; 
	# at the center
	foreach my $orig_map_row( @{$ui->{map}} ){
		push @map,	[ 
						($ui->{ ext_tile }) x $ui->{ map_area_w },
							@$orig_map_row,
						($ui->{ ext_tile }) x $ui->{ map_area_w }
					]
	}
	# add at bottom
	push @map,map { [ ($ui->{ ext_tile }) x ( $original_map_w + $ui->{ map_area_w } * 2 ) ]} 0..$ui->{ map_area_h } ;
	
	@{$ui->{map}} = @map;
	
	# set hero coordinates
	$ui->{hero_x} += $ui->{ map_area_w } ; #+ 1; 
	$ui->{hero_y} += $ui->{ map_area_h } + 1; 
	
	# set top left corner coordinates (of the real map data)
	$ui->{real_map_first}{x} = $ui->{ map_area_w } ;
	$ui->{real_map_first}{y} = $ui->{ map_area_h } + 1;
	
	# set bottom right corner coordinates
	$ui->{real_map_last}{y} = $#{$ui->{map}} - $ui->{ map_area_h } ; 
	$ui->{real_map_last}{x} = $#{$ui->{map}->[0]} - $ui->{ map_area_w } ;
	
	# beautify map 
	$ui->beautify_map();
		
	
	$ui->set_no_scrolling_area();
	
}

sub beautify_map{
	# letter used in map, descr  possible renders,  possible fg colors,   speed penality

	my $ui = shift;
	foreach my $row( $ui->{real_map_first}{y} .. $ui->{real_map_last}{y} - 1 ){ # WATCH this - 1 !!!!!
		foreach my $col( $ui->{real_map_first}{x} .. $ui->{real_map_last}{x} ){
			
			# if the letter is defined in %terrain
			if(exists $terrain{ $ui->{map}[$row][$col] } ){
				# FOREGROUND COLOR 
				my $color = ref $terrain{ $ui->{map}[$row][$col] }[2] eq 'ARRAY' 	?
					$terrain{ $ui->{map}[$row][$col] }[2]->
						[int( rand( $#{$terrain{ $ui->{map}[$row][$col] }[2]}+1))]  :
							$terrain{ $ui->{map}[$row][$col] }[2]  					;
				# BACKGROUND COLOR			
				my $bg_color = ref $terrain{ $ui->{map}[$row][$col] }[3] eq 'ARRAY' 	?
					$terrain{ $ui->{map}[$row][$col] }[3]->
						[int( rand( $#{$terrain{ $ui->{map}[$row][$col] }[3]}+1))]  :
							$terrain{ $ui->{map}[$row][$col] }[3]  					;
				
				# CHARCTER TO DISPLAY
				my $to_display = ref $terrain{ $ui->{map}[$row][$col] }[1] eq 'ARRAY' 	?
					$terrain{ $ui->{map}[$row][$col] }[1]->
						[int( rand( $#{$terrain{ $ui->{map}[$row][$col] }[1]}+1))]  :
							$terrain{ $ui->{map}[$row][$col] }[1]  					;			
				
				# final tile is anonymous array
				$ui->{map}[$row][$col] = [
						$bg_color.$color.$to_display.RESET	, # 0 to display
						$ui->{map}[$row][$col]				, # 1 original letter of terrain
						( $ui->{masked_map} ? 0 : 1)		, # 2 unmasked
				];
			}
			# letter not defined in %terrain final tile is anonymous array too
			else {  $ui->{map}[$row][$col]  =  [ $ui->{map}[$row][$col], $ui->{map}[$row][$col], 0]}
		}
	}
}
sub set_no_scrolling_area{
	my $ui = shift;
	
	if ( $ui->{no_scroll} == 0 ){
		if ( $ui->{hero_side} eq 'S' ){  
			$ui->{no_scroll_area}{min_x} = $ui->{hero_x} - int($ui->{map_area_w} / 4);
			$ui->{no_scroll_area}{min_y} = $ui->{hero_y} - int($ui->{map_area_h} / 2);
			
			$ui->{no_scroll_area}{max_y} = $ui->{hero_y};
			$ui->{no_scroll_area}{max_x} = $ui->{hero_x} + int($ui->{map_area_w} / 4);			
		}
		elsif ( $ui->{hero_side} eq 'N' ){ 
			$ui->{no_scroll_area}{min_x} = $ui->{hero_x} - int($ui->{map_area_w} / 4);
			$ui->{no_scroll_area}{min_y} = $ui->{hero_y}; 
			
			$ui->{no_scroll_area}{max_x} = $ui->{hero_x} + int($ui->{map_area_w} / 4);
			$ui->{no_scroll_area}{max_y} = $ui->{hero_y} + int($ui->{map_area_h} / 2);				
		}		
		elsif ( $ui->{hero_side} eq 'E' ){
			$ui->{no_scroll_area}{min_x} = $ui->{hero_x} - int($ui->{map_area_w} / 2);
			$ui->{no_scroll_area}{min_y} = $ui->{hero_y} - int($ui->{map_area_h} / 4);
			
			$ui->{no_scroll_area}{max_x} = $ui->{hero_x} ;
			$ui->{no_scroll_area}{max_y} = $ui->{hero_y} + int($ui->{map_area_h} / 4 );						
		}
		elsif ( $ui->{hero_side} eq 'W' ){
			$ui->{no_scroll_area}{min_x} = $ui->{hero_x};
			$ui->{no_scroll_area}{min_y} = $ui->{hero_y} - int($ui->{map_area_h} / 4);
			
			$ui->{no_scroll_area}{max_x} = $ui->{hero_x} + int($ui->{map_area_w} / 2);
			$ui->{no_scroll_area}{max_y} = $ui->{hero_y} + int($ui->{map_area_h} / 4);			
		}
		else{die}
	}
	print "DEBUG: no_scroll area from $ui->{no_scroll_area}{min_y}-$ui->{no_scroll_area}{min_x} ",
			"to $ui->{no_scroll_area}{max_y}-$ui->{no_scroll_area}{max_x}\n" if $debug;
	
	local $ui->{map}->[$ui->{no_scroll_area}{min_y}][$ui->{no_scroll_area}{min_x}] = ['+', '', 1];
	local $ui->{map}->[$ui->{no_scroll_area}{max_y}][$ui->{no_scroll_area}{max_x}] = ['+', '', 1];
	
	#print 	"DEBUG: map extended with no_scroll vertexes (+ signs):\n",map{ join'',@$_,$/ } @{$ui->{map}} if $debug > 1;
	print 	"DEBUG: map extended (now each tile is [to_display,terrain letter, masked] ) with no_scroll vertexes (+ signs):\n",
			map{ join'',(map{ $_->[0] }@$_),$/ } @{$ui->{map}} if $debug > 1;
	
	
	
}

sub set_hero_pos{
	my $ui = shift;
	# hero position MUST be on a side and NEVER on a corner
	print "DEBUG: original map size; rows: 0..",$#{$ui->{map}}," cols: 0..",$#{$ui->{map}->[0]}," \n" if $debug;
	foreach my $row ( 0..$#{$ui->{map}} ){
		foreach my $col ( 0..$#{$ui->{map}->[$row]} ){
			if ( ${$ui->{map}}[$row][$col] eq 'X' ){
				print "DEBUG: (original map) found hero at row $row col $col\n" if $debug;
				# clean this tile
				${$ui->{map}}[$row][$col] = ' ';
				$ui->{hero_y} = $row;
				$ui->{hero_x} = $col;
				if    ( $row == 0 )						{ $ui->{hero_side} = 'N' }
				elsif ( $row == $#{$ui->{map}} )		{ $ui->{hero_side} = 'S' }
				elsif ( $col == 0 )						{ $ui->{hero_side} = 'W' }
				elsif ( $col == $#{$ui->{map}->[$row]} ){ $ui->{hero_side} = 'E' }
				else									{ die "Hero side not found!" }
			}				
		}
	}	
}

# sub validate_conf{
	# my %conf = @_;
	# # set internally to get coord of the first element of the map
	# $conf{ real_map_first} = { x => undef, y => undef };
	# # set internally to get coord of the last element of the map
	# $conf{ real_map_last} = { x => undef, y => undef };

	# $conf{ cls_cmd }     //= $^O eq 'MSWin32' ? 'cls' : 'clear';
	
	
	# # get and set internally
	# $conf{ hero_x } = undef;
	# $conf{ hero_y } = undef;
	# $conf{ hero_side } = '';
	
	
	# # get and set internally
	# $conf{ map } //=[];
	# $conf{ map_off_x } = 0;
	# $conf{ map_off_y } = 0;
	# $conf{ scrolling } = 0;

	# $conf{ no_scroll_area} = { min_x=>'',max_x=>'',min_y=>'',max_y=>'' };
	
		
	# return %conf;
# }



1; # End of Game::Term::UI
__DATA__

useful article linked by Corion: http://journal.stuffwithstuff.com/2014/07/15/a-turn-based-game-loop/

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

how to install a font for cmd.exe https://www.techrepublic.com/blog/windows-and-office/quick-tip-add-fonts-to-the-command-prompt/

raster fonts ?? https://github.com/idispatch/raster-fonts	

https://www.thefreewindows.com/3467/edit-your-fonts-with-fony/ fony.exe mmh.. no ttf

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
		
		# provided by Term::ANSIColor
		BLACK           RED             GREEN           YELLOW
		BLUE            MAGENTA         CYAN            WHITE 
		
		# provided by Game::Term
		B_BLACK  		B_RED      		B_GREEN   		B_YELLOW  
		B_BLUE   		B_MAGENTA  		B_CYAN    		B_WHITE



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


