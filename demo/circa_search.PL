#!/usr/bin/perl -w
#
# Simple perl exmple to interface with module Search::Circa::Search
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2002/08/19 10:21:38 $

use strict;
use Getopt::Long;
use lib '/path/to/circa';
use CircaConf;
use Search::Circa::Search;


my $search = new Search::Circa::Search;
my ($id,$url,$langue,$update,$create);
GetOptions (   "id=s"     => \$id,
	       "url=s"     => \$url,
	       "langue=s" => \$langue,
	       "update=s" => \$update,
	       "create=s" => \$create)|| &usage();
if (@ARGV==0 or $ARGV[0] eq '-h' or $ARGV[0] eq '--help')  {&usage(); }
my $word = $ARGV[0];
if (!$id) {$id=1;}

# Connection à MySQL
if (!$search->connect) {
  die "Erreur à la connection MySQL:$DBI::errstr\n";
}

if (($word) && ($id))  {
  print "Search::Circa::Search $Search::Circa::Search::VERSION\n";
  print "Recherche sur $word\n\n";
  my ($resultat,$links,$indice) = 
    $search->search(undef,$word,0,$id,$langue,$url,$create,$update);
  if (!$resultat and !$links and !$indice) {
    print "Error on search. Did you have one account and url in database ?\n";
  }
  else { print $resultat if ($resultat); }
  }
$search->close;

sub usage {
print "
******************************************************************
            Search::Circa::Search $Search::Circa::Search::VERSION

Usage: search.pl 'list of word' [+id=id_site]
  [+url=url_restric] [+langue=] [+create=] [+update=]

+id=i     : Restrict to site with responsable with id i
+url=u    : Restrict to site with url beginning with u
+langue=l : Restrict to langue l
+create=c : Only url added after this date c (YYYY/MM/DD)
+update=u : Only url updated after this date u (YYYY/MM/DD)
******************************************************************\n";
  exit;
}
