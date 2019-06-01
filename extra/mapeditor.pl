use strict;
use warnings;
use Tk;
use Tk::Pane;

my $mw = Tk::MainWindow->new(-bg=>'ivory',-title=>'Game::Term Map Editor');
$mw->geometry("400x200+0+0");




my $top_frame = $mw->Frame( -borderwidth => 2, -relief => 'groove',)->pack(-expand => 1, -fill => 'x');

my $maxy = 30;
my $maxx = 5; 

my $tile_w = 10;
my $tile_h = 10;

my @aoa = map{ [ ('X') x $maxx  ] } 0..$maxy-1;
#use Data::Dump; dd @aoa;



                          
my $current = 'current tile (y-x): 0-0';
$top_frame->Label( 
					-text=>"using ",
					-textvariable=>\$current,
)->pack( );

$top_frame->Label( 
					-text=>"using "
)->pack( );

$top_frame->Label(	
					-text => "Rows: 0-"
)->pack(-side => 'left');

$top_frame->Entry(	
					-width => 3,
					-borderwidth => 4, 
					-textvariable => \$maxy
)->pack(-side => 'left');

$top_frame->Label(	
					-text => "columns: 0-"
)->pack(-side => 'left');

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
					-command => sub{exit}
)->pack(-side => 'left',-padx=>5);


my $map_frame = $mw->Scrolled(	'Frame',
								-scrollbars => 'osoe',
								-background=>'ivory',
								-borderwidth => 10, 
								-relief => 'groove',
)->pack(); #-expand => 1, -fill => 'both'

my $c = $map_frame->Canvas( 
								-width => $maxx * $tile_w,
								-height => $maxy * $tile_h,
 )->pack(-expand => 1, -fill => 'both');
 
 
# my $c = $map_frame->Canvas(
						# -bg => 'black',
                         # -width => $maxx x $tile_w,
								# -height => $maxy x $tile_h,
             # #-scrollbars => 'osoe',
             # #-scrollregion => [ 0, 0, $canvasWidth, $canvasHeight ],
              # )->pack;
			  
			  
# my $tx = $c->createText(20, 10, -text => 'X: UNKNOWN');
# my $ty = $c->createText(20, 25, -text => 'Y: UNKNOWN');
$c->Tk::bind('<Motion>' =>
		[	
			sub {
				my ($e,$x,$y) = (@_);
				# $c->itemconfigure($tx, -text => "X: $x");
				# $c->itemconfigure($ty, -text => "Y: $y");
				#
				$current = "current tile (y-x): $y-$x";
			},
			
			Ev('x'), Ev('y')
		]);



				  
MainLoop();