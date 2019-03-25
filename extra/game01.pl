use strict;
use warnings;

use Game::Term::UI;
use Game::Term::Configuration;
use Game::Term::Map;

use Data::Dump;

my $conf = Game::Term::Configuration->new();
# $conf->{interface}{ext_tile} = '?';
# $conf->{interface}{masked_map} = 0;
# $conf->{interface}{fog_of_war} = 0;

my $ui = Game::Term::UI->new( configuration => $conf );
#my $ui = Game::Term::UI->new( configuration => $conf, debug => 1 );
#dd $conf;

$ui->run();