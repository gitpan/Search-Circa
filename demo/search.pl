#!/usr/bin/perl -w
#
# Simple perl exmple to interface with module Search::Circa::Search
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2001/08/29 17:47:50 $

use strict;
use Getopt::Long;
use CircaConf;
use lib $CircaConf::CircaDir;
use Search::Circa::Search;


my $search = new Search::Circa::Search;

if (@ARGV==0)
  {
print "
******************************************************************
            Search::Circa::Search $Search::Circa::Search::VERSION

Usage: search.pl +word='list of word' [+id=id_site]
  [+url=url_restric] [+langue=] [+create=] [+update=]

+word=w   : Search words w
+id=i     : Restrict to site with responsable with id i
+url=u    : Restrict to site with url beginning with u
+langue=l : Restrict to langue l
+create=c : Only url added after this date c (YYYY/MM/DD)
+update=u : Only url updated after this date u (YYYY/MM/DD)
******************************************************************\n";
  exit;
  }

my ($id,$url,$langue,$update,$create,$word);
GetOptions (   "word=s"   => \$word,
	       "id=s"     => \$id,
	       "url=s"     => \$url,
	       "langue=s" => \$langue,
	       "update=s" => \$update,
	       "create=s" => \$create);
if (!$id) {$id=1;}

# Connection à MySQL
if (!$search->connect($CircaConf::User,
			    $CircaConf::Password,
			    $CircaConf::Database,
			    $CircaConf::Host))
  {die "Erreur à la connection MySQL:$DBI::errstr\n";}

if (($word) && ($id))
  {
  print "Search::Circa::Search $Search::Circa::Search::VERSION\n";
  print "Recherche sur $word\n\n";
  my ($resultat,$links,$indice) = 
    $search->search(undef,$word,0,$id,$langue,$url,$create,$update);
  print $resultat;
  }
$search->close;
