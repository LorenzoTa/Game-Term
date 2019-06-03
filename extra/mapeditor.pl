use strict;
use warnings;
use Tk;
use Tk::Pane;
use Data::Dump;

my $mw = Tk::MainWindow->new(-bg=>'ivory',-title=>'Game::Term Map Editor');
$mw->geometry("700x600+0+0");

$mw->optionAdd('*font', 'Courier 12');
$mw->optionAdd( '*Entry.background',   'lavender' );
$mw->optionAdd( '*Entry.font',   'Courier 12 bold'  );


# TOP FRAME
my $top_frame0 = $mw->Frame( -borderwidth => 2, -relief => 'groove',)->pack(-anchor=>'ne', -fill => 'both');

$top_frame0->Label( -text=>"press a key to set brush (or choose it from the below menu)\n".
							"hold CRTL and move the pointer to paint",)->pack( -side=>'top');


my $top_frame1 = $mw->Frame( -borderwidth => 2,-relief => 'groove',)->pack(-anchor=>'ne', -fill => 'both');

my $default_char = ' ';

my $maxy = 29;
my $maxx = 29; 

my $tile_w = 15;
my $tile_h = 15;

my $cur_tile_lbl = 'tile (y-x): 0-0';

$top_frame1->Label( -textvariable=>\$cur_tile_lbl,)->pack( -side=>'left',-padx=>5);


my $list_brushes = $top_frame1->Optionmenu( -textvariable=>\$default_char, )->pack( -side=>'right' ,-padx=>5);
$top_frame1->Label( -text=>"actual brush: ",)->pack( -side=>'right' ,-padx=>5);

foreach my $charnum (32..127){
	$list_brushes->addOptions( chr($charnum) );
}


my $top_frame2 = $mw->Frame( -borderwidth => 2, 
							-relief => 'groove',
)->pack(-anchor=>'ne', -fill => 'both');

$top_frame2->Label(-text => "rows: 0-")->pack(-side => 'left');

$top_frame2->Entry(	
					-width => 3,
					-borderwidth => 4, 
					-textvariable => \$maxy
)->pack(-side => 'left',-padx=>5);

$top_frame2->Label(-text => "columns: 0-")->pack(-side => 'left',-padx=>5);

$top_frame2->Entry(	
					-width => 3,
					-borderwidth => 4, 
					-textvariable => \$maxx
)->pack(-side => 'left',,-padx=>5);

$top_frame2->Button(	-padx=> 5,
					-text => "new",
					-borderwidth => 4, 
					-command => sub{ &setup_new }
)->pack(-side => 'left',-padx=>5);



$top_frame2->Button(	-padx=> 5,
					-text => "toggle grid",
					-borderwidth => 4, 
					-command => sub{&toggle_grid()},
)->pack(-side => 'right',-padx=>5);

$top_frame2->Button(	-padx=> 5,
					-text => "export",
					-borderwidth => 4, 
					-command => sub{&export_aoa()},
)->pack(-side => 'right',-padx=>5);

# $top_frame2->Button(	-padx=> 5,
					# -text => "import",
					# -borderwidth => 4, 
					# -command => sub{exit}
# )->pack(-side => 'right',-padx=>5);




# MAP FRAME
my $map_frame = $mw->Scrolled(	'Frame',
								-scrollbars => 'osoe',
								-relief => 'groove',
)->pack(-anchor=>'n',-expand => 1, -fill => 'both');

 
my $canvas;
my $grid_show = 1;
my @aoa;
setup_new();	

				  
MainLoop();


sub setup_new{
	$default_char = ' ';
	
	$canvas->packForget if Tk::Exists($canvas); 
	
	@aoa = map{ [ ($default_char) x ($maxx + 1)  ] } 0..$maxy;
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
	$canvas->Tk::bind("<Button-1>", [ \&get_coord, Ev('x'), Ev('y') ]);
	#$canvas->Tk::bind("<Button-3>",  [ \&reset_motion, Ev('x'), Ev('y') ]);
	
	
	$canvas->Tk::bind("<Alt-Motion>", [ \&save_coord, Ev('x'), Ev('y') ]);
	
}

sub save_coord {
	my ($canv, $x, $y) = @_;
	#print "SETtING (x,y) = ", $canv->canvasx($x), ", ", $canv->canvasy($y), "\n";
	my $cur = $canv->find('withtag' =>'current' );
	my @list = grep{$_ ne 'current'} $canv->gettags($cur);
	
	$cur_tile_lbl = "tile (y-x): $list[0] " if $list[0];
	
	if ( $list[0] ){
		print "SET $y - $x\n";
		$canv->itemconfigure($cur, -fill => "red");
		my ($y,$x)=split /-/, $list[0];
		$aoa[$y][$x]= $default_char;
	}
}


sub set_default_char {
		my ($canv, $k) = @_;
		print "DEBUG [$k] was pressed..\n";
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
			print "setting brush to [$k]\n";
		}
		elsif( exists $other_chars{$k} ){
			$default_char = $other_chars{$k};
			print "setting brush to [$other_chars{$k}]\n";
		}
		else{
			print "WARNING: cannot use [$k] as char to draw!\n";
		}
		
		
}

sub set_coord {
	my ($canv, $x, $y) = @_;
	#print "SETtING (x,y) = ", $canv->canvasx($x), ", ", $canv->canvasy($y), "\n";
	my $cur = $canv->find('withtag' =>'current' );
	my @list = grep{$_ ne 'current'} $canv->gettags($cur);
	
	$cur_tile_lbl = "tile (y-x): $list[0] " if $list[0];
	
	if ( $list[0] ){
		print "SET $y - $x\n";
		$canv->itemconfigure($cur, -text=> $default_char);
		my ($y,$x)=split /-/, $list[0];
		$aoa[$y][$x]= $default_char;
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
sub get_coord {
	my ($canv, $x, $y) = @_;
	#print "(x,y) = ", $canv->canvasx($x), ", ", $canv->canvasy($y), "\n";
	my $cur = $canv->find('withtag' =>'current' );
	my @list = grep{$_ ne 'current'} $canv->gettags($cur);
	
	$cur_tile_lbl = "tile (y-x): $list[0] " if $list[0];
	
}
sub export_aoa{
	foreach my $row (0..$#aoa){
		foreach my $col( 0..$#{$aoa[$row]} ){
			print $aoa[$row][$col];
		}
		print "\n";	
	}
}

sub set_default_char_BIS {
	# https://www.tcl.tk/man/tcl/TkCmd/keysyms.htm
	my %tcl_chars = (
			space   =>      32,
			exclam  =>      33,
			quotedbl        =>      34,
			numbersign      =>      35,
			dollar  =>      36,
			percent =>      37,
			ampersand       =>      38,
			quoteright      =>      39,
			parenleft       =>      40,
			parenright      =>      41,
			asterisk        =>      42,
			plus    =>      43,
			comma   =>      44,
			minus   =>      45,
			period  =>      46,
			slash   =>      47,
			0       =>      48,
			1       =>      49,
			2       =>      50,
			3       =>      51,
			4       =>      52,
			5       =>      53,
			6       =>      54,
			7       =>      55,
			8       =>      56,
			9       =>      57,
			colon   =>      58,
			semicolon       =>      59,
			less    =>      60,
			equal   =>      61,
			greater =>      62,
			question        =>      63,
			at      =>      64,
			A       =>      65,
			B       =>      66,
			C       =>      67,
			D       =>      68,
			E       =>      69,
			F       =>      70,
			G       =>      71,
			H       =>      72,
			I       =>      73,
			J       =>      74,
			K       =>      75,
			L       =>      76,
			M       =>      77,
			N       =>      78,
			O       =>      79,
			P       =>      80,
			Q       =>      81,
			R       =>      82,
			S       =>      83,
			T       =>      84,
			U       =>      85,
			V       =>      86,
			W       =>      87,
			X       =>      88,
			Y       =>      89,
			Z       =>      90,
			bracketleft     =>      91,
			backslash       =>      92,
			bracketright    =>      93,
			asciicircum     =>      94,
			underscore      =>      95,
			quoteleft       =>      96,
			a       =>      97,
			b       =>      98,
			c       =>      99,
			d       =>      100,
			e       =>      101,
			f       =>      102,
			g       =>      103,
			h       =>      104,
			i       =>      105,
			j       =>      106,
			k       =>      107,
			l       =>      108,
			m       =>      109,
			n       =>      110,
			o       =>      111,
			p       =>      112,
			q       =>      113,
			r       =>      114,
			s       =>      115,
			t       =>      116,
			u       =>      117,
			v       =>      118,
			w       =>      119,
			x       =>      120,
			y       =>      121,
			z       =>      122,
			braceleft       =>      123,
			bar     =>      124,
			braceright      =>      125,
			asciitilde      =>      126,
			nobreakspace    =>      160,
			exclamdown      =>      161,
			cent    =>      162,
			sterling        =>      163,
			currency        =>      164,
			yen     =>      165,
			brokenbar       =>      166,
			section =>      167,
			diaeresis       =>      168,
			copyright       =>      169,
			ordfeminine     =>      170,
			guillemotleft   =>      171,
			notsign =>      172,
			hyphen  =>      173,
			registered      =>      174,
			macron  =>      175,
			degree  =>      176,
			plusminus       =>      177,
			twosuperior     =>      178,
			threesuperior   =>      179,
			acute   =>      180,
			mu      =>      181,
			paragraph       =>      182,
			periodcentered  =>      183,
			cedilla =>      184,
			onesuperior     =>      185,
			masculine       =>      186,
			guillemotright  =>      187,
			onequarter      =>      188,
			onehalf =>      189,
			threequarters   =>      190,
			questiondown    =>      191,
			Agrave  =>      192,
			Aacute  =>      193,
			Acircumflex     =>      194,
			Atilde  =>      195,
			Adiaeresis      =>      196,
			Aring   =>      197,
			AE      =>      198,
			Ccedilla        =>      199,
			Egrave  =>      200,
			Eacute  =>      201,
			Ecircumflex     =>      202,
			Ediaeresis      =>      203,
			Igrave  =>      204,
			Iacute  =>      205,
			Icircumflex     =>      206,
			Idiaeresis      =>      207,
			Eth     =>      208,
			Ntilde  =>      209,
			Ograve  =>      210,
			Oacute  =>      211,
			Ocircumflex     =>      212,
			Otilde  =>      213,
			Odiaeresis      =>      214,
			multiply        =>      215,
			Ooblique        =>      216,
			Ugrave  =>      217,
			Uacute  =>      218,
			Ucircumflex     =>      219,
			Udiaeresis      =>      220,
			Yacute  =>      221,
			Thorn   =>      222,
			ssharp  =>      223,
			agrave  =>      224,
			aacute  =>      225,
			acircumflex     =>      226,
			atilde  =>      227,
			adiaeresis      =>      228,
			aring   =>      229,
			ae      =>      230,
			ccedilla        =>      231,
			egrave  =>      232,
			eacute  =>      233,
			ecircumflex     =>      234,
			ediaeresis      =>      235,
			igrave  =>      236,
			iacute  =>      237,
			icircumflex     =>      238,
			idiaeresis      =>      239,
			eth     =>      240,
			ntilde  =>      241,
			ograve  =>      242,
			oacute  =>      243,
			ocircumflex     =>      244,
			otilde  =>      245,
			odiaeresis      =>      246,
			division        =>      247,
			oslash  =>      248,
			ugrave  =>      249,
			uacute  =>      250,
			ucircumflex     =>      251,
			udiaeresis      =>      252,
			yacute  =>      253,
			thorn   =>      254,
			ydiaeresis      =>      255,
	
	);

		
 }

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
