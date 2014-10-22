#!/usr/bin/perl -w
#
# Simple perl example to interface with module Search::Circa::Indexer
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2001/10/14 17:33:48 $
#

use strict;
use Getopt::Long;
use CircaConf;
use lib $CircaConf::CircaDir;
use Search::Circa::Indexer;

my $indexor = new Search::Circa::Indexer(
  'author'              => 'circa@alianwebserver.com', # Responsable du moteur
  'temporate'           => 1,  # Temporise les requetes sur le serveur de 8s.
  'facteur_keyword'     => 15, # <meta name="KeyWords"
  'facteur_description' => 10, # <meta name="description"
  'facteur_titre'       => 10, # <title></title>
  'facteur_full_text'   => 1,  # reste
  'facteur_url'         => 10,
  'nb_min_mots'         => 3,  # facteur min pour garder un mot
  'niveau_max'          => 7,  # Niveau max � indexer
  'indexCgi'            => 0,  # Suit les diff�rents liens des CGI 
					 # (ex: ?nom=toto&riri=eieiei)
);
#$indexor->proxy('http://195.154.155.254:3128');
if ( (@ARGV==0) || ($ARGV[0] eq '-h')) {&usage();}
  

my ($create, $drop, $update, $parse_new, $add, $addSite, $addLocal, $stats,
    $export, $import, $depth, $drop_id, $debug);
GetOptions 
  (
   "create"      => \$create,
   "drop"        => \$drop,
   "update=s"    => \$update,
   "parse_new=s" => \$parse_new,
   "depth_max"   => \$depth,
   "add_site=s"  => \$add,
   "add=s"       => \$addSite,
   "addLocal=s"  => \$addLocal,
   "stats=s"     => \$stats,
   "export"      => \$export,
   "import"      => \$import,
   "drop_id=s"   => \$drop_id,
   "debug=s"     => \$debug);
$indexor->{DEBUG}=$debug if ($debug);
if (!$indexor->connect($CircaConf::User,
			     $CircaConf::Password,
			     $CircaConf::Database,
			     $CircaConf::Host)) 
  {die "Erreur � la connection MySQL:$DBI::errstr\n";}

# Drop table
if ($drop) {$indexor->drop_table_circa;print "Tables droped\n";}
# Drop account
if ($drop_id) {$indexor->drop_table_circa_id($drop_id); print "Account $drop_id deleted\n";}
# Create table
if ($create){$indexor->create_table_circa;print "Tables created\n";}
# Add url
if ($add)
  {
  my @l=split(/,/,$add);
  if (!$l[1]) {$l[1]=1;}
  ($indexor->add_site(@l) && print $l[0]," added\n" ) || print $DBI::errstr,"\n";
  }
# Add site
if ($addSite)
  {
  my @l=split(/,/,$addSite);
  my $aa; if ($l[3]) {$aa=1;} else {$aa=0;}
  my $id = $indexor->addSite($l[0],$l[1],$l[2],$aa,undef,undef,$l[3]);
  print "Url $l[0] added and account $id created\n";
  }
# Add local site
if ($addLocal)
  {
  my @l=split(/,/,$addLocal);
  $indexor->addLocalSite(@l);
  print "Url $l[0] added\n";
  }

# Update index
if ($update) 
  {
    my @l = split(/,/,$update);
    die "Usage: $0 +update=nb_jours,id_account\n" if (@l<2);
    $indexor->update(@l);
    print "Update done.\n";
  }

# Read url not parsed
if ($parse_new)
  {
    if ($depth) 
      {
	my ($nbIndexe,$nbAjoute,$nbWords,$nbWordsGood,$depth)=(0,1,0,0,0);
	while ($nbAjoute)
	  {
	   ($nbIndexe,$nbAjoute,$nbWords,$nbWordsGood) = 
	     $indexor->parse_new_url($parse_new);
	   print 
"\n---------------------------------------------------------------------------
Profondeur $depth : $nbIndexe pages index�es, $nbAjoute pages ajout�es, ".
"$nbWordsGood mots index�s, $nbWords mots lus
---------------------------------------------------------------------------\n";
	   $depth++;
	 }	
      }
    else {
	  my ($nbIndexe,$nbAjoute,$nbWords,$nbWordsGood) 
	    = $indexor->parse_new_url($parse_new);
	   print "$nbIndexe pages index�es, $nbAjoute pages ajout�es, ".
	     "$nbWordsGood mots index�s, $nbWords mots lus\n";
	 }
  }

# export data
if ($export) {$indexor->export;}

# import data
if ($import) {$indexor->import_data;}

# statistiques
if ($stats)
  {
    my $id=$stats;
    my $ref = $indexor->admin_compte($id);
    if (!$$ref{'responsable'}) {print "No account $id\n";}
    else
      {
	print "Informations generales sur le compte $id\n\n",
	display("Responsable",    $$ref{'responsable'}),
	display("Titre du compte",$$ref{'titre'}),
	display("Nombre d'url" ,  $$ref{'nb_links'}),
	display("Nombre d'url parsees",$$ref{'nb_links_parsed'}),
	display("Nombre d'url parsees et valides",$$ref{'nb_links_valide'}),
	display("Profondeur maximum",$$ref{'depth_max'}),
        display("Nombre de mots",$$ref{'nb_words'}),
	display("Last index",$$ref{'last_index'}),
	display("Racine du site",$$ref{'racine'}),"\n";

	print "Les 10 mots les plus souvents trouv�s:\n";
	my $refer = $indexor->most_popular_word(10,$id);
	my @l = reverse sort { $$refer{$a} <=> $$refer{$b} } keys %$refer;
	foreach (@l) { print display($_,$$refer{$_}); }
      }
  }

# Close connection
$indexor->close;

# For stats option
sub display
  {
    my ($message,$var)=@_;
    return $message.'.' x (50 - length($message.$var)).$var."\n";
  }

# For -h option
sub usage
  {
print <<EOF;
******************************************************************
            Circa Indexer version $Search::Circa::Indexer::VERSION

Usage: admin.pl [-h] [+create] [+drop] [+export] [+import]
  [+update=nb_day,id_site] [+stats=id_site]  [+drop_id=id]
  [+parse_new=id_site] [+add=url, [email], [titre], [masque] ]
  [+add_site=url [,id] ] [+debug=(1-4)] 
  [+addLocal=file,url,email,titre,urlRacine,pathRacine]

******************************************************************
EOF

if (@ARGV>0)
  {
print <<EOF;
-------
+create: Create table for Circa
-------
+drop : Drop table for Circa (All Mysql data lost !)
-------
+drop_id=id : Drop table for account id
-------
+export : Export all data in circa.sql
-------
+import : Import data from circa.sql
-------
+stats=id : Give some stat about site id
-------
+parse_new=id [+depth_max]: Parse and indexe url last added for site id
-------
+add_site=url [,id] : Add url in account id. If no id, 1 is used.
-------
+update=nb_day,id : Update data for site id last indexed nb_day ago
  If page aren't updated since last index, page not fetched.
-------
+add=url, [email], [titre], [template] : Add url to database and
create a new account.

$0 +add=http://www.alianwebserver.com/,
              alian\@alianwebserver.com,
              "Alian Web Server",
              "/home/alian/circa/circa.htm"
-------
+addLocal=url,email,titre,file,urlRacine,pathRacine :
Add a local url to database and create a new account.

Ex: $0 +addLocal=http://www.alianwebserver.com/index.html,
           alian\@alianwebserver.com,
           "Alian Web Server",
           file:///suse/index.html,
           file:///suse/,
           http://www.alianwebserver.com
-------

If first time you use Circa, you can do:
$0 +create +add=http://www.monsite.com +parse_new=1 +depth_max
for index your first url.

EOF
  }
  exit;
}
