#!/usr/bin/perl -w
#
# Simple CGI interface to module Search::Circa::Indexer
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.
# Take a look in admin.htm
# $Date: 2001/09/23 10:37:11 $
#

use strict;
use CGI qw/:standard :html3 :netscape escape unescape/;
use CGI::Carp qw/fatalsToBrowser/;
use CircaConf;
use lib $CircaConf::CircaDir;
use Search::Circa::Indexer;
use Cwd;

$|=1;

my $masque        = $CircaConf::TemplateDir."admin.htm";
my $masqueClients = $CircaConf::TemplateDir; # rep ou deposer les masques
my $importDir     = $CircaConf::export;
my $indexor = new Search::Circa::Indexer;
#$indexor->proxy("http://192.168.100.70:3128");

my $cgi = new CGI;
print header,$indexor->start_classic_html($cgi);
#if (defined $ENV{'MOD_PERL'}) {print "Mode mod_perl<br>\n";}
#else {print "Mode cgi<br>\n";}
if (!$indexor->connect($CircaConf::User,
			     $CircaConf::Password,
			     $CircaConf::Database,
			     $CircaConf::Host)) 
  {die "Erreur � la connection MySQL:$DBI::errstr\n";}

# Drop table
if (param('drop')) 
  {$indexor->drop_table_circa; print h1("Tables supprim�es"); }

# Drop compte
if (param('dropSite')) 
  { $indexor->drop_table_circa_id(param('id')); print h1("Comte supprim�"); }

# Create table
if (param('create')) 
  {$indexor->create_table_circa; print h1("Tables cr��es"); }

# Add site
if (param('url'))
  {
  $indexor->addSite(param('url'),param('email'),param('titre'),
		    param('categorieAuto'),$cgi,$masqueClients);
  print h1("Site ajout�");
  }
# export data
if (param('export')) {$indexor->export(undef,$importDir);}
# import data
if (param('import')) {$indexor->import_data(undef,$importDir);}
# Add local site
if (param('local_url'))
  {
  $indexor->addLocalSite(
    param('local_url'),
    param('email'),
    param('titre'),
    param('local_file'),
    param('url_racine'),
    param('local_file_site'),
    param('categorieAuto'),
    $cgi,
    $masqueClients);
  print h1("Site ajout�");
  }

# Read url not parsed
if (param('parse_new'))
  {
  my ($nbIndexe,$nbAjoute,$nbWords,$nbWordsGood) 
    = $indexor->parse_new_url(param('id'));
  print "$nbIndexe pages index�es, $nbAjoute pages ajout�es, ",
  "$nbWordsGood mots index�s, $nbWords mots lus\n";
  }

# Update index
if (param('update')) 
  {$indexor->update(param('nb_jours'),param('id'));}

my @l = (0,1);
my %tab=(0=>'Non',1=>'Oui');
my $list = $cgi->scrolling_list(-'name'=>'categorieAuto',
                           -'values'=>\@l,
                           -'size'=>1,
                           -'labels'=>\%tab);
# Liste des variables � substituer dans le template
my %vars = ('liste_site'=> $indexor->get_liste_site($cgi),'categories'=>$list);
# Affichage du resultat
print $indexor->fill_template($masque,\%vars),end_html;

# Close connection
$indexor->close;
