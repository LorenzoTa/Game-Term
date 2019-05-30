use strict;
use warnings;
use Tk;


my $mw = Tk::MainWindow->new(-bg=>'ivory',-title=>'Game::Term Map Editor');
$mw->geometry("400x200+0+0");




my $top_frame = $mw->Frame( -borderwidth => 2, -relief => 'groove',)->pack(-expand => 1, -fill => 'both');

my $maxy = 30;
my $maxx = 30;                           
my $current = 'X';
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
)->pack(-side => 'left',-expand => 1,-padx=>5);

$top_frame->Button(	-padx=> 5,
					-text => "import",
					-borderwidth => 4, 
					-command => sub{exit}
)->pack(-side => 'left',-expand => 1,-padx=>5);

$top_frame->Button(	-padx=> 5,
					-text => "export",
					-borderwidth => 4, 
					-command => sub{exit}
)->pack(-side => 'left',-expand => 1,-padx=>5);


my $map_frame = $mw->Frame(  -background=>'ivory',
                              -borderwidth => 10, -relief => 'groove',
)->pack(-expand => 1, -fill => 'both');
				  
MainLoop();