use strict;
use warnings;
use Tk;
use Tk::Pane;
use Data::Dump;

my $mw = Tk::MainWindow->new(-bg=>'ivory',-title=>'Game::Term Map Editor');
$mw->geometry("600x600+0+0");



# TOP FRAME
my $top_frame = $mw->Frame( -borderwidth => 2, 
							-relief => 'groove',
)->pack(-anchor=>'ne', -fill => 'both');

my $default_char = ' ';

my $maxy = 80;
my $maxx = 80; 

my $tile_w = 10;
my $tile_h = 10;

my @aoa = map{ [ ($default_char) x $maxx  ] } 0..$maxy-1;
#use Data::Dump; dd @aoa;



                          
my $current = 'current tile (y-x): 0-0';

$top_frame->Label( -textvariable=>\$current,)->pack( -side=>'left');

$top_frame->Label( -text=>"painting  with:",)->pack( -side=>'left' );

$top_frame->Label( -textvariable=>\$default_char,)->pack( -side=>'left' );


$top_frame->Label(-text => "Rows: 0-")->pack(-side => 'left');

$top_frame->Entry(	
					-width => 3,
					-borderwidth => 4, 
					-textvariable => \$maxy
)->pack(-side => 'left');

$top_frame->Label(-text => "columns: 0-")->pack(-side => 'left');

$top_frame->Entry(	
					-width => 3,
					-borderwidth => 4, 
					-textvariable => \$maxx
)->pack(-side => 'left');

$top_frame->Button(	-padx=> 5,
					-text => "new",
					-borderwidth => 4, 
					-command => sub{exit}
)->pack(-side => 'left',-padx=>5);

$top_frame->Button(	-padx=> 5,
					-text => "import",
					-borderwidth => 4, 
					-command => sub{exit}
)->pack(-side => 'left',-padx=>5);

$top_frame->Button(	-padx=> 5,
					-text => "export",
					-borderwidth => 4, 
					-command => sub{&export_aoa()},
)->pack(-side => 'left',-padx=>5);



$top_frame->Button(	-padx=> 5,
					-text => "toggle grid",
					-borderwidth => 4, 
					-command => sub{&toggle_grid()},
)->pack(-side => 'left',-padx=>5);

# MAP FRAME
my $map_frame = $mw->Scrolled(	'Frame',
								-scrollbars => 'osoe',
								#-background=>'pink',
								#-borderwidth => 10, 
								-relief => 'groove',
)->pack(-anchor=>'n',-expand => 1, -fill => 'both');

# my $c = $mw->Scrolled(	'Canvas',
						# -background=>'Navy',
								# -scrollbars => 'osoe',
								# -width => 300,#$maxx * $tile_w,
								# -height => 300,#$maxy * $tile_h,
 # )->pack(-anchor=>'ne',-expand => 1, -fill => 'both');
 
 
my $canvas = $map_frame->Canvas(
							-bg => 'ivory',
							-width => $maxx * $tile_w,
							-height => $maxy * $tile_h,
             #-scrollbars => 'osoe',
             #-scrollregion => [ 0, 0, $canvasWidth, $canvasHeight ],
              )->pack(-anchor=>'n',-expand => 1, -fill => 'both');
#$canvas->createGrid(0,0, $tile_w, $tile_h, lines=>1,-width=>1);
my $grid_show = 1;
$canvas->createGrid(0,0, $tile_w, $tile_h, lines=>1,-width=>1,-tags=>['thegrid']);
 
my $start_y = 0;
my $end_y = $start_y + $tile_h;

my $start_x = 0;
my $end_x = $start_x + $tile_w;

my @map;

foreach my $row (0..$#aoa){
	#print " $start_y - $end_y\n";
	
	foreach my $col( 0..$#{$aoa[$row]} ){
		#print $aoa[$row][$col];
		#print " $start_x-$end_x ";
		$map[$row][$col]= $canvas->createText(
								($start_x + $end_x ) / 2,
								($start_y + $end_y ) / 2,
								
								 -text => $aoa[$row][$col],
								 -tags => ["$row-$col"]
		);
		$start_x += $tile_w;
		$end_x	+= $tile_w;
	}
	#print "\n";
	#reset X
	$start_x = 0;
	$end_x = $start_x + $tile_w;
	$start_y += $tile_h;
	$end_y	+= $tile_h;
	
}



$mw->bind("<Key>", [ \&set_default_char, Ev('K') ] );
$mw->bind("<Key-space>", [ \&set_default_char_to_space, Ev('K') ] );
#$canvas->Tk::bind("<Motion>", [ \&get_coord, Ev('x'), Ev('y') ]);
$canvas->Tk::bind("<Control-Motion>", [ \&set_coord, Ev('x'), Ev('y') ]);
$canvas->Tk::bind("<Button-1>", [ \&get_coord, Ev('x'), Ev('y') ]);
#$canvas->Tk::bind("<Button-3>",  [ \&reset_motion, Ev('x'), Ev('y') ]);


				  
MainLoop();
sub set_default_char {
		my ($canv, $k) = @_;
		print "DEBUG [$k] was pressed..\n";
		return 0 unless $k =~ /^.$/;
		print "setting char to [$k]\n";
		$default_char = $k;
}
sub set_default_char_to_space {
		my ($canv, $k) = @_;
		print "setting char to [ ]\n";
		$default_char = ' ';
}
sub set_coord {
	my ($canv, $x, $y) = @_;
	#print "SETtING (x,y) = ", $canv->canvasx($x), ", ", $canv->canvasy($y), "\n";
	my $cur = $canv->find('withtag' =>'current' );
	my @list = grep{$_ ne 'current'} $canv->gettags($cur);
	
	$current = "current tile (y-x): $list[0] " if $list[0];
	
	if ( $list[0] ){
		print "SET $y - $x\n";
		$canv->itemconfigure($cur, -text=> $default_char);
		my ($y,$x)=split /-/, $list[0];
		$aoa[$y][$x]= $default_char;
		#use Data::Dump; dd $cur,$map[$y][$x];
	}
	#$canvas->Tk::bind("<Motion>", [ \&set_coord, Ev('x'), Ev('y') ]);
}

sub reset_motion {
	$canvas->Tk::bind("<Motion>", [ \&get_coord, Ev('x'), Ev('y') ]);
}

sub toggle_grid{
	if ( $grid_show ){
		#my @withtag = $canvas->find('withtag','thegrid');
		#$withtag[0]->itemconfigure(-state => 'disabled',-disabledcolor => undef);
		#$canvas->itemconfigure('thegrid',-state => 'disabled');
		$canvas->itemconfigure('thegrid',-color=>'ivory');
		#$grid = $canvas->createGrid(0,0, $tile_w, $tile_h, lines=>1,-width=>1,-state=>'hidden',-color=>undef);
		# $grid->itemconfigure(-state => 'disabled',-disabledcolor => undef);
		# $grid = undef;
	}
	else{
		#$grid = $canvas->createGrid(0,0, $tile_w, $tile_h, lines=>1,-width=>1,-tags=>['thegrid']);
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
	
	$current = "current tile (y-x): $list[0] " if $list[0];
	
}
sub export_aoa{
	foreach my $row (0..$#aoa){
		foreach my $col( 0..$#{$aoa[$row]} ){
			print $aoa[$row][$col];
		}
		print "\n";	
	}
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
				
				# $current = "current tile (y-x): $y-$x ".
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
