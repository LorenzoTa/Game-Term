use strict;
use warnings;
use Tk;
use Tk::Pane;
use Tk::FileSelect;
use File::Spec;

my $debug = 0;
my $default_char = ' ';

my $maxy = 29;
my $maxx = 29; 

my $tile_w = 15;
my $tile_h = 15;

my $cur_tile_lbl = 'tile (y-x): 0-0';

my $canvas;
my $grid_show = 1;

# the final datastructure
my @aoa = map{ [ ($default_char) x ($maxx + 1)  ] } 0..$maxy;

# the hash of selected tiles
my %selected;
# help window
my $hw;
# export window
my $exp_win;
# initial dir for load file
my $start_dir = File::Spec->rel2abs('.');
# the choosen file



my $mw = Tk::MainWindow->new(-bg=>'ivory',-title=>'Game::Term Map Editor');
$mw->geometry("550x600+0+0");

$mw->optionAdd('*font', 'Courier 12');
$mw->optionAdd( '*Entry.background',   'lavender' );
$mw->optionAdd( '*Entry.font',   'Courier 12 bold'  );


# TOP FRAME
my $top_frame0 = $mw->Frame( -borderwidth => 2, -relief => 'groove',)->pack(-anchor=>'ne', -fill => 'both');

# $top_frame0->Label( -text=>"press a key to set brush (or choose it from the below menu)\n".
							# "hold CRTL and move the pointer to paint with actual brush\n".
							# "hold ALT to slect, SHIFT to deselect (DEL to clear selection)",)->pack( -side=>'top');
$top_frame0->Label(-text => "rows:0-")->pack(-side => 'left',-padx=>5);

$top_frame0->Entry(	
					-width => 3,
					-borderwidth => 4, 
					-textvariable => \$maxy
)->pack(-side => 'left');

$top_frame0->Label(-text => "columns:0-")->pack(-side => 'left');

$top_frame0->Entry(	
					-width => 3,
					-borderwidth => 4, 
					-textvariable => \$maxx
)->pack(-side => 'left',);

$top_frame0->Button(-padx=> 5,
					-text => "new",
					-borderwidth => 4, 
					-command => sub{ &setup_new }
)->pack(-side => 'left',-padx=>5);


$top_frame0->Button(-padx=> 5,
					-text => "load/save",
					-borderwidth => 4, 
					-command => sub{ load_save() }
)->pack(-side => 'left',-padx=>5);

$top_frame0->Button(-padx=> 5,
					-text => "help",
					-borderwidth => 4, 
					-command => sub{ help() }
)->pack(-side => 'left',-padx=>5);
							
# FRAME 1							
my $top_frame1 = $mw->Frame( -borderwidth => 2,-relief => 'groove',)->pack(-anchor=>'ne', -fill => 'both');



$top_frame1->Label( -textvariable=>\$cur_tile_lbl,)->pack( -side=>'left',-padx=>5);


my $list_brushes = $top_frame1->Optionmenu( -textvariable=>\$default_char, )->pack( -side=>'right' ,-padx=>5);
$top_frame1->Label( -text=>"actual brush: ",)->pack( -side=>'right' ,-padx=>5);

foreach my $charnum (32..127){
	$list_brushes->addOptions( chr($charnum) );
}

# FRAME 2
my $top_frame2 = $mw->Frame( -borderwidth => 2, 
							-relief => 'groove',
)->pack(-anchor=>'ne', -fill => 'both');

$top_frame2->Button(-padx=> 5,
					-text => "export selection",
					-borderwidth => 4, 
					-command => sub{&export_selection()},
)->pack( -side => 'left' );


$top_frame2->Button(-padx=> 5,
					-text => "toggle grid",
					-borderwidth => 4, 
					-command => sub{&toggle_grid()},
)->pack(-side => 'right',-padx=>5);

# $top_frame2->Button(-padx=> 5,
					# -text => "export map",
					# -borderwidth => 4, 
					# -command => sub{&export_aoa()},
# )->pack(-side => 'right',-padx=>5);





# MAP FRAME
my $map_frame = $mw->Scrolled(	'Frame',
								-scrollbars => 'osoe',
								-relief => 'groove',
)->pack(-anchor=>'n',-expand => 1, -fill => 'both');

 



setup_new();	

				  
MainLoop();


sub load_save{
	if ( Exists($exp_win) ){
		$exp_win->focus;
		$exp_win->deiconify( ) if $exp_win->state() eq 'iconic';
		$exp_win->raise( ) if $exp_win->state() eq 'withdrawn';
		return 0;
	}
	else{
		$exp_win = $mw->Toplevel( );
		#$exp_win->geometry("550x300");
		$exp_win->title(" Game::Term Map Editor load and save ");
		$exp_win->focus;
		
		# LOAD FRAME
		my $load_fr0 = $exp_win->Frame( -borderwidth => 2, 
										-relief => 'groove',
		)->pack(-anchor=>'ne', -expand=>1, -fill => 'x');
		
		my $load_fr1 = $load_fr0->Frame( 
		)->pack(-anchor=>'n', -expand=>1, -fill => 'x');
		
		$load_fr1->Label(-text => "load:")->pack(-side => 'left',-padx=>5);
		
		my $to_load = '';
		
		$load_fr1->Label(-textvariable => \$to_load)
					->pack(-side => 'left',-expand=>1,-fill=>'x',-padx=>5);
		
		my $load_fr2 = $load_fr0->Frame( 
		)->pack(-anchor=>'s', -expand=>1, -fill => 'x');		
		
		$load_fr2->Button(	
				-padx=> 5,
				-text => "choose file",
				-borderwidth => 4, 
				-command => sub{
						my $FSref = $exp_win->FileSelect(-directory => $start_dir);
						$to_load = $FSref->Show;
						$to_load = File::Spec->rel2abs($to_load);
						print "ready to load $to_load\n";
						my($volume,$directories,$file) =
							File::Spec->splitpath( $to_load || File::Spec->rel2abs('.') );
						$start_dir = File::Spec->catdir( $volume,$directories );
						print "START DIR: $start_dir\n";
				},
		)->pack(-side => 'left',-padx=>5);
		my $after_data = 0;
		$load_fr2->Checkbutton(
								-text => 'look after __DATA__', 
								-variable => \$after_data)->pack( -side=>'left',-padx=>5);
		$load_fr2->Button(
				-padx=> 5,
				-text => "load",
				-borderwidth => 4, 
				-command => sub{
						open my $fh, '<', $to_load or die "unable to load [$to_load]! ";
						@aoa = undef;
						my $data_found;
						#print "\nimported map:\n";
						my $index = 0;
						my $length = undef;
						while (<$fh>){
							if($after_data){
								if ($_ eq "__DATA__\n"){
									
									$data_found = 1;
									next;
								}
								next unless $data_found;
							}
							#print;
							chomp;
							my @chars = split //,$_;
							$length = @chars unless $length;
							die "different columns at row $index"
								if $length != @chars;
							#print "chars [@chars]\n";
							$aoa[$index]=[@chars];
							$index++;
						}
						$maxy = $index - 1;
						$maxx = $length - 1;
						setup_new();
						print "\nafter import\n";
						export_aoa();
						$exp_win->destroy;
				},
		)->pack(-side => 'left',-padx=>5);
		
		
		# SAVE FRAME
		my $save_fr0 = $exp_win->Frame( -borderwidth => 2, -relief => 'groove',)->pack(-anchor=>'ne', -expand=>1, -fill => 'both');
		
		my $save_fr1 = $save_fr0->Frame( 
		)->pack(-anchor=>'n', -expand=>1, -fill => 'x');
		
		$save_fr1->Label(-text => "save to:")->pack(-side => 'left',-padx=>5);
		
		my $save_dir = $start_dir;
		
		$save_fr1->Label(-textvariable => \$save_dir)->pack(-side => 'left',-padx=>5);
		
		# my $save_fr1 = $save_fr0->Frame( 
		# )->pack(-anchor=>'n', -expand=>1, -fill => 'x');
		
		
		my $save_fr2 = $save_fr0->Frame( 
		)->pack(-anchor=>'n', -expand=>1, -fill => 'x');
		
		$save_fr2->Button(	
				-padx=> 5,
				-text => "choose folder",
				-borderwidth => 4, 
				-command => sub{
						$save_dir = $mw->chooseDirectory(-initialdir => $start_dir);
						#print "SAVE DIR: $save_dir\n";
						#$to_save = File::Spec->catfile($dir,);
				},
		)->pack(-side => 'left',-padx=>5);
		
		$save_fr2->Label( -text=>"filename",)->pack( -side=>'left' ,-padx=>5);
		
		my $save_file = '';
		$save_fr2->Entry(	
							-width => 20,
							-borderwidth => 4, 
							-textvariable => \$save_file
		)->pack(-side => 'left',);

		$save_fr2->Button(-padx=> 5,
							-text => "save",
							-borderwidth => 4, 
							-command => sub{ 
								my $save_path = File::Spec->catfile($save_dir,$save_file);
								open my $fh, '>', $save_path 
									or die "unable to save to [$save_path]! ";
								my $previous = select $fh;
								export_aoa();
								select $previous;
								print "succesfully saved current map to $save_path\n";
								$exp_win->destroy;								
							}
		)->pack(-side => 'left',-padx=>5);
		
	}

}

# sub load_file{
	# my $FSref = $exp_win->FileSelect(-directory => $start_dir);
	# my $file = $FSref->Show;
# }

sub help {
	if ( Exists($hw) ){
		$hw->focus;
		$hw->deiconify( ) if $hw->state() eq 'iconic';
		$hw->raise( ) if $hw->state() eq 'withdrawn';
		return 0;
	}
    $hw = $mw->Toplevel( );
    $hw->geometry("550x300");
    $hw->title("Game::Term Map Editor help ");
    my $txt = $hw->Scrolled('Text',
                      -background=>	'white',
                      -scrollbars => 'osoe',
                      
    )->pack(-expand => 1, -fill => 'both');

    $txt->Contents(
					"CHOOSE A BRUSH:\n".
					"-press a key to set brush (or choose it from the brush menu)\n\n".
					"DRAW:\n".
					"-Left click a tile to draw the current character in it\n".
					"-hold CRTL and move the pointer to paint with actual brush\n\n".
					"COORDINATES SELECTION:\n".
					"-hold ALT and move the pointer to slect\n".
					"-hold SHIFT and move the pointer to deselect\n".
					"-hit DEL to clear selection\n\n"
	);
    $hw->focus;;
}

sub setup_new{
	$default_char = ' ';
	
	$canvas->packForget if Tk::Exists($canvas); 
	
	#@aoa = map{ [ ($default_char) x ($maxx + 1)  ] } 0..$maxy;
	$canvas = $map_frame->Canvas(
							-bg => 'ivory',
							-width 	=> $maxx * $tile_w + $tile_w - 2, # -2 correction for the grid
							-height => $maxy * $tile_h + $tile_h - 2,
              )->pack(-anchor=>'n',-expand => 1, -fill => 'both');
	
	$canvas->focusForce;
	
	$canvas->createGrid(0,0, $tile_w, $tile_h, lines=>1,-width=>1,-tags=>['thegrid']);
	 
	my $start_y = 0;
	my $end_y = $start_y + $tile_h;

	my $start_x = 0;
	my $end_x = $start_x + $tile_w;

	foreach my $row (0..$#aoa){
		foreach my $col( 0..$#{$aoa[$row]} ){
			$canvas->createText(
									($start_x + $end_x ) / 2,
									($start_y + $end_y ) / 2,
									
									 -text => $aoa[$row][$col],
									 -tags => ["$row-$col"],
									 -font=> 'Courier 14 bold'
			);
			$start_x += $tile_w;
			$end_x	+= $tile_w;
		}
		$start_x = 0;
		$end_x = $start_x + $tile_w;
		$start_y += $tile_h;
		$end_y	+= $tile_h;
	
	}
	$mw->bind("<Key>", [ \&set_default_char, Ev('K') ] );
	#$mw->bind("<Key-space>", [ \&set_default_char_to_space, Ev('K') ] );
	#$canvas->Tk::bind("<Motion>", [ \&get_coord, Ev('x'), Ev('y') ]);
	$canvas->Tk::bind("<Control-Motion>", [ \&set_coord, Ev('x'), Ev('y') ]);
	#$canvas->Tk::bind("<Button1-Motion>", [ \&set_coord, Ev('x'), Ev('y') ]);
	$canvas->Tk::bind("<Button-1>", [ \&set_coord, Ev('x'), Ev('y') ]);
	#$canvas->Tk::bind("<Button-3>",  [ \&reset_motion, Ev('x'), Ev('y') ]);
	
	
	$canvas->Tk::bind("<Alt-Motion>", [ \&select_coord, Ev('x'), Ev('y') ]);
	$canvas->Tk::bind("<Shift-Motion>", [ \&deselect_coord, Ev('x'), Ev('y') ]);
	$canvas->Tk::bind("<Delete>", [ \&clear_selection, Ev('x'), Ev('y') ]);
}

sub clear_selection{
	my $canv = shift;
	foreach my $key ( %selected ){
		$canv->delete( $selected{$key} );
		#delete $selected{$key};		
	}
	undef %selected;
}

sub deselect_coord{
	my ($canv, $x, $y) = @_;
	my $cur = $canv->find('withtag' =>'current' );
	my @list = grep{$_ ne 'current'} $canv->gettags($cur);
		
	if ( $list[0] ){
		
		my($tile_y,$tile_x) = split/-/,$list[0];
		$cur_tile_lbl = "tile (y-x): $tile_y-$tile_x ";
		
		if (exists $selected{"$tile_y-$tile_x"} ){
			print "DESELECTING $tile_y-$tile_x\n";
			$canv->delete( $selected{"$tile_y-$tile_x"} );
			delete $selected{"$tile_y-$tile_x"};		
		}
	}
}
sub select_coord {
	my ($canv, $x, $y) = @_;
	my $cur = $canv->find('withtag' =>'current' );
	my @list = grep{$_ ne 'current'} $canv->gettags($cur);
	
	
	if ( $list[0] ){
		
		my($tile_y,$tile_x) = split/-/,$list[0];
		$cur_tile_lbl = "tile (y-x): $tile_y-$tile_x ";
		print "SELECTING $tile_y-$tile_x\n"
			unless exists $selected{"$tile_y-$tile_x"};		
		# CALCULATE SMALL SQUARE CORNERS
		my $min_y = $tile_y * $tile_h;
		my $min_x = $tile_x * $tile_w;
		my $max_y = $tile_y * $tile_h + $tile_h;
		my $max_x = $tile_x * $tile_w + $tile_w;
		
		# SAVE SELECTION
		$selected{"$tile_y-$tile_x"} 
		= 
		$canv->createRectangle($min_x,$min_y,$max_x,$max_y,-outline=>'red',-width=>2)
		unless exists $selected{"$tile_y-$tile_x"};

	}
}

sub export_selection{
	#my @pairs = sort keys %selected;
	my %grouped;
	map{ 
		my $orig = $_ ;
		my ($y,$x) = split /-/,$_;
		push @{$grouped{$y}},$orig; 
	} sort keys %selected;
	foreach my $key ( sort {$a<=>$b} keys %grouped ){
		print map{s/-/,/;"[$_],"} @{$grouped{$key}};
		print "\n";
	}
}

sub set_default_char {
		my ($canv, $k) = @_;
		print "DEBUG [$k] was pressed..\n" if $debug;
		#return 0 unless $k =~ /^.$/;
		my %other_chars = (
				space		=> ' ',
				at			=> '@',
				numbersign	=> '#',				
				backslash 	=> '\\',
				bar			=> '|',
				exclam		=> '!',
				quotedbl	=> '"',
				#sterling	=> '£', # BUG ???
				dollar		=> '$',
				percent		=> '%',
				ampersand	=> '&',
				slash		=> '/',
				parenleft	=> '(',
				parenright	=> ')',
				equal		=> '=',
				quoteright	=>	"'",
				question	=> '?',
				asciicircum	=> '^',
				comma 		=> ',',
				period		=> '.',
				minus		=> '-',
				semicolon	=> ';',
				colon		=> ':',
				underscore	=> '_',
				plus		=> '+',
				asterisk	=> '*',
				# degree		=> '°', # BUG ?
				greater		=> '>',
				less		=> '<',
								
				
		);
		if( $k =~ /^.$/){
			$default_char = $k;
			print "setting brush to [$k]\n" if $debug;
		}
		elsif( exists $other_chars{$k} ){
			$default_char = $other_chars{$k};
			print "setting brush to [$other_chars{$k}]\n"if $debug;
		}
		else{
			print "WARNING: cannot use [$k] as char to draw!\n"if $debug;
		}
		
		
}

sub set_coord {
	my ($canv, $x, $y) = @_;
	#print "SETtING (x,y) = ", $canv->canvasx($x), ", ", $canv->canvasy($y), "\n";
	my $cur = $canv->find('withtag' =>'current' );
	my @list = grep{$_ ne 'current'} $canv->gettags($cur);
	
		if ( $list[0] ){
		
		$canv->itemconfigure($cur, -text=> $default_char);
		my ($tile_y,$tile_x)=split /-/, $list[0];
		unless ($cur_tile_lbl eq "tile (y-x): $tile_y-$tile_x"){
			$cur_tile_lbl = "tile (y-x): $tile_y-$tile_x";
			print "SET $tile_y - $tile_x\n";
		}
		$aoa[$tile_y][$tile_x]= $default_char;
	}
}


sub toggle_grid{
	if ( $grid_show ){
		$canvas->itemconfigure('thegrid',-color=>'ivory');
	}
	else{
		$canvas->itemconfigure('thegrid',-color=>'black');
	}
	$grid_show = !$grid_show;
}

# from https://www.perlmonks.org/?node_id=987407 zentara rules!!
# sub get_coord {
	# my ($canv, $x, $y) = @_;
	# #print "(x,y) = ", $canv->canvasx($x), ", ", $canv->canvasy($y), "\n";
	# my $cur = $canv->find('withtag' =>'current' );
	# my @list = grep{$_ ne 'current'} $canv->gettags($cur);
	
	# $cur_tile_lbl = "tile (y-x): $list[0] " if $list[0];
	
# }
sub export_aoa{
	foreach my $row (0..$#aoa){
		foreach my $col( 0..$#{$aoa[$row]} ){
			print $aoa[$row][$col];
		}
		print "\n";	
	}
}

# sub set_default_char_BIS {
	# # https://www.tcl.tk/man/tcl/TkCmd/keysyms.htm
	# my %tcl_chars = (
			# space   =>      32,
			# exclam  =>      33,
			# quotedbl        =>      34,
			# numbersign      =>      35,
			# dollar  =>      36,
			# percent =>      37,
			# ampersand       =>      38,
			# quoteright      =>      39,
			# parenleft       =>      40,
			# parenright      =>      41,
			# asterisk        =>      42,
			# plus    =>      43,
			# comma   =>      44,
			# minus   =>      45,
			# period  =>      46,
			# slash   =>      47,
			# 0       =>      48,
			# 1       =>      49,
			# 2       =>      50,
			# 3       =>      51,
			# 4       =>      52,
			# 5       =>      53,
			# 6       =>      54,
			# 7       =>      55,
			# 8       =>      56,
			# 9       =>      57,
			# colon   =>      58,
			# semicolon       =>      59,
			# less    =>      60,
			# equal   =>      61,
			# greater =>      62,
			# question        =>      63,
			# at      =>      64,
			# A       =>      65,
			# B       =>      66,
			# C       =>      67,
			# D       =>      68,
			# E       =>      69,
			# F       =>      70,
			# G       =>      71,
			# H       =>      72,
			# I       =>      73,
			# J       =>      74,
			# K       =>      75,
			# L       =>      76,
			# M       =>      77,
			# N       =>      78,
			# O       =>      79,
			# P       =>      80,
			# Q       =>      81,
			# R       =>      82,
			# S       =>      83,
			# T       =>      84,
			# U       =>      85,
			# V       =>      86,
			# W       =>      87,
			# X       =>      88,
			# Y       =>      89,
			# Z       =>      90,
			# bracketleft     =>      91,
			# backslash       =>      92,
			# bracketright    =>      93,
			# asciicircum     =>      94,
			# underscore      =>      95,
			# quoteleft       =>      96,
			# a       =>      97,
			# b       =>      98,
			# c       =>      99,
			# d       =>      100,
			# e       =>      101,
			# f       =>      102,
			# g       =>      103,
			# h       =>      104,
			# i       =>      105,
			# j       =>      106,
			# k       =>      107,
			# l       =>      108,
			# m       =>      109,
			# n       =>      110,
			# o       =>      111,
			# p       =>      112,
			# q       =>      113,
			# r       =>      114,
			# s       =>      115,
			# t       =>      116,
			# u       =>      117,
			# v       =>      118,
			# w       =>      119,
			# x       =>      120,
			# y       =>      121,
			# z       =>      122,
			# braceleft       =>      123,
			# bar     =>      124,
			# braceright      =>      125,
			# asciitilde      =>      126,
			# nobreakspace    =>      160,
			# exclamdown      =>      161,
			# cent    =>      162,
			# sterling        =>      163,
			# currency        =>      164,
			# yen     =>      165,
			# brokenbar       =>      166,
			# section =>      167,
			# diaeresis       =>      168,
			# copyright       =>      169,
			# ordfeminine     =>      170,
			# guillemotleft   =>      171,
			# notsign =>      172,
			# hyphen  =>      173,
			# registered      =>      174,
			# macron  =>      175,
			# degree  =>      176,
			# plusminus       =>      177,
			# twosuperior     =>      178,
			# threesuperior   =>      179,
			# acute   =>      180,
			# mu      =>      181,
			# paragraph       =>      182,
			# periodcentered  =>      183,
			# cedilla =>      184,
			# onesuperior     =>      185,
			# masculine       =>      186,
			# guillemotright  =>      187,
			# onequarter      =>      188,
			# onehalf =>      189,
			# threequarters   =>      190,
			# questiondown    =>      191,
			# Agrave  =>      192,
			# Aacute  =>      193,
			# Acircumflex     =>      194,
			# Atilde  =>      195,
			# Adiaeresis      =>      196,
			# Aring   =>      197,
			# AE      =>      198,
			# Ccedilla        =>      199,
			# Egrave  =>      200,
			# Eacute  =>      201,
			# Ecircumflex     =>      202,
			# Ediaeresis      =>      203,
			# Igrave  =>      204,
			# Iacute  =>      205,
			# Icircumflex     =>      206,
			# Idiaeresis      =>      207,
			# Eth     =>      208,
			# Ntilde  =>      209,
			# Ograve  =>      210,
			# Oacute  =>      211,
			# Ocircumflex     =>      212,
			# Otilde  =>      213,
			# Odiaeresis      =>      214,
			# multiply        =>      215,
			# Ooblique        =>      216,
			# Ugrave  =>      217,
			# Uacute  =>      218,
			# Ucircumflex     =>      219,
			# Udiaeresis      =>      220,
			# Yacute  =>      221,
			# Thorn   =>      222,
			# ssharp  =>      223,
			# agrave  =>      224,
			# aacute  =>      225,
			# acircumflex     =>      226,
			# atilde  =>      227,
			# adiaeresis      =>      228,
			# aring   =>      229,
			# ae      =>      230,
			# ccedilla        =>      231,
			# egrave  =>      232,
			# eacute  =>      233,
			# ecircumflex     =>      234,
			# ediaeresis      =>      235,
			# igrave  =>      236,
			# iacute  =>      237,
			# icircumflex     =>      238,
			# idiaeresis      =>      239,
			# eth     =>      240,
			# ntilde  =>      241,
			# ograve  =>      242,
			# oacute  =>      243,
			# ocircumflex     =>      244,
			# otilde  =>      245,
			# odiaeresis      =>      246,
			# division        =>      247,
			# oslash  =>      248,
			# ugrave  =>      249,
			# uacute  =>      250,
			# ucircumflex     =>      251,
			# udiaeresis      =>      252,
			# yacute  =>      253,
			# thorn   =>      254,
			# ydiaeresis      =>      255,
	
	# );

		
 # }

__DATA__
https://www.perlmonks.org/?node_id=691267

$canvas->bind('move', '<1>', sub {&mobileStart();});
$canvas->bind('move', '<B1-Motion>', sub {&mobileMove();});
$canvas->bind('move', '<ButtonRelease>', sub {&mobileStop();});


my $dx;
my $dy;

sub mobileStart {
      my $ev = $canvas->XEvent;
      ($dx, $dy) = (0 - $ev->x, 0 - $ev->y);
      $canvas->raise('current');
      print "START MOVE->  $dx  $dy\n";
}


sub mobileMove {
      my $ev = $canvas->XEvent;
      $canvas->move('current', $ev->x + $dx, $ev->y +$dy);
      ($dx, $dy) = (0 - $ev->x, 0 - $ev->y);
      print "MOVING->  $dx  $dy\n";
}


sub mobileStop{&mobileMove;}



use Data::Dump; dd @map;			  
			  
# $canvas->Tk::bind('<Motion>' =>
		# [	
			# sub {
				# my ($e,$x,$y) = (@_);
				
				# $cur_tile_lbl = "current tile (y-x): $y-$x ".
					# $canvas->canvasy($y);#.' '.$canvas->canvasx();
				# #print "(x,y) = ", $canvas->canvasx($x), ", ", $canvas->canvasy($y), "\n";
			# },
			
			# Ev('x'), Ev('y')
		# ],
# );

$canvas->Tk::bind(
		
		'<Button-1>' =>
		[
			sub{
				my ($e,$x,$y) = (@_);
				print "(x,y) = ", $canvas->canvasx($x), ", ", $canvas->canvasy($y), "\n";
			},
			Ev('x'), Ev('y')
		]
		
);
