#!/usr/bin/perl -w
#
# Simple CGI interface to module Search::Circa::Search
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2001/08/29 17:47:50 $

use strict;
use CGI qw/:standard :html3 :netscape escape unescape/;
use CGI::Carp qw/fatalsToBrowser/;
use CircaConf;
use lib $CircaConf::CircaDir;
use Search::Circa::Search;
use Search::Circa::Annuaire;

# Default file template for result
my $masque = $CircaConf::TemplateDir."circa.htm";
my $cgi = new CGI;
print header;

my $id = param('id') || 1;
# Navigation par mot-clef
if ( param('word') )
  {
    my $search = new Search::Circa::Search;
    # Connection à MySQL
    if (!$search->connect($CircaConf::User,
				  $CircaConf::Password,
				  $CircaConf::Database,
				  $CircaConf::Host))
	{die "Erreur à la connection MySQL:$DBI::errstr\n";}

    # Interrogation du moteur et tri du resultat par facteur
    my $mots=param('word');
    my $first = param('first') ||0;
    my ($masque) = $search->categorie->get_masque($id) || $masque;
    my ($resultat,$links,$indice) = $search->search(
								    undef,$mots,$first,
								    param('id')||1,
								    param('langue')||undef,
								    param('url')||undef,
								    param('create')||undef,
								    param('update')||undef,
								    param('categorie')||undef,
								    $cgi
								   );
  if ($indice==0) {$resultat="<p>Aucun document trouvé.</p>";}
  if ($indice!=0) {$indice="$indice page(s) trouvée(s)";} else {$indice=' ';}
  # Liste des variables à substituer dans le template
  my %vars = ('resultat'     => $resultat,
            'titre'    => "Recherche sur ".$search->get_name_site($id),
            'listeLiensSuivPrec'=> $links,
            'words'    => param('word'),
            'id'    => param('id'),
            'categorie'    => param('categorie')||0,
            'listeLangue'  => $search->get_liste_langue($cgi),
            'nb'    => $indice);
    # Affichage du resultat
    print $search->fill_template($masque,\%vars),end_html;
    $search->close;
  }
# Navigation par catégorie
else
  {    
    my $annuaire = new Search::Circa::Annuaire;
    # Connection à MySQL
    if (!$annuaire->connect($CircaConf::User,
				    $CircaConf::Password,
				    $CircaConf::Database,
				    $CircaConf::Host))
	{die "Erreur à la connection MySQL:$DBI::errstr\n";}
    my ($categorie,$id);
    if (!param('categorie')) {$categorie=0;}
    else {$categorie=param('categorie');}
    if (!param('id')) {$id=1;}
    else {$id=param('id');}
    my ($masque) = $annuaire->categorie->get_masque($id,$categorie) || $masque;
    my ($titre,@cates) = $annuaire->GetCategoriesOf($categorie,$id);
    my ($sites,$liens) = $annuaire->GetSitesOf($categorie,
							     $id,
							     undef,
							     param('first'));
    # Substitution dans le template
    my %vars = 
	('resultat'    => $sites,
	 'categories1' => join(' ',@cates[0..$#cates/2]),
	 'categories2' => join(' ',@cates[($#cates/2)+1..$#cates]),
	 'titre'       => h3('Annuaire').'<p class="categorie">'.($titre).'</p>',
	 'listeLiensSuivPrec'=> $liens,
	 'words'       => ' ',
	 'categorie'   => $categorie,
	 'id'          => $id,
	 #     'listeLangue' => $search->get_liste_langue($cgi),
	 'nb'          => 0);
    # Affichage du resultat
    print $annuaire->fill_template($masque,\%vars),end_html;
    $annuaire->close;
  }

