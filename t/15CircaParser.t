#!/usr/bin/perl -Tw
use strict;
use Test::More tests => 18;
use Search::Circa::Indexer;
$|=1;

$ENV{PATH}=''; $ENV{ENV}='';

 SKIP: {
  skip('No advanced test asked', 18)
    if (! -e ".t");

  #
  # Search::Circa::Indexer
  #
  my $circa = new Search::Circa::Indexer;
  open(F,".t"); $circa->{_DB} = <F>; close(F);
  ok( $circa->connect, "Search::Circa::Indexer->connect");

  my $id = 1;

  #$circa->{DEBUG}=4;
  my %url = 
    (
     'url'              => 'http://www.1001cartes.com',
     'local_url'        => 'file://usr/local/apache/htdocs',
     'browse_categorie' => '1',
     'niveau'           => '0',
     'categorie'        => '0',
     'titre'            => 'page test',
     'description'      => 'une page de test',
     'langue'           => 'fr',
     'last_check'       => '0000-00-00',
     'last_update'      => '0000-00-00',
     'valide'           => 1,
     'parse'            => 0,
     'id'               => 1,
    );

  #
  # Search::Circa::Parser
  #
  $circa->set_host_indexed($url{url});
  foreach (qw/doc zip ps gif jpg gz pdf png deb xls ppt GIF css
	   js wav mid/) {
    ok (!$circa->Parser->check_links("a", "http://$url{url}/toto.$_"),
	"Search::Circa::Parser->check_links $_");
  }

  ok ($circa->Parser->look_at($url{url}, $url{id}, $id),
      "Search::Circa::Parser->look at");
}
