#!/usr/bin/perl -w
#
# Simple perl example to interface with module Search::Circa::Indexer
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2002/08/19 10:20:59 $
#

use strict;
use Getopt::Long;
use lib '/path/to/circa';
use CircaConf;
use Search::Circa::Indexer;

my $indexor = new Search::Circa::Indexer(%CircaConf::conf);
#$indexor->proxy('http://195.154.155.254:3128');
if ( (@ARGV==0) || ($ARGV[0] eq '-h')) {&usage();}
  

my ($create, $drop, $update, $parse_new, $add, $addSite, $addLocal, $stats,
    $export, $import, $depth, $drop_id, $debug, $addLocalPrompt, $exportId);
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
   "addLocalPrompt" => \$addLocalPrompt,
   "stats=s"     => \$stats,
   "export"      => \$export,
   "exportId=s"  => \$exportId,
   "import"      => \$import,
   "drop_id=s"   => \$drop_id,
   "debug=s"     => \$debug) || &usage();
$indexor->{DEBUG}=$debug if ($debug);
if (!$indexor->connect($CircaConf::User,
			     $CircaConf::Password,
			     $CircaConf::Database,
			     $CircaConf::Host)) 
  {die "Erreur à la connection MySQL:$DBI::errstr\n";}

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
  ($indexor->URL->add($l[1], (url => $l[0], valide =>1)) 
			     && print $l[0]," added\n" ) 
    || print $DBI::errstr,"\n";
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
# Add local site with prompt
if ($addLocalPrompt)
  {
    my @l;
    push(@l, $indexor->prompt("Url http ?",
					"http://www.alianwebserver.com/index.html"));
    push(@l, $indexor->prompt("Email responsable ?",'root@localhost'));
    push(@l, $indexor->prompt("Titre site ?",'titre de mon site'));
    push(@l, $indexor->prompt("Url local ?",
					"file:///usr/local/apache/htdocs/index.html"));
    my $v = 'file:///usr/local/apache/htdocs/';
    if ($l[3] =~/^(.*\/)[\w\.]*/) {$v=$1; }
    push(@l, $indexor->prompt("Url local racine ?", $v));
    $v = 'http://www.alianwebserver.com/';
    if ($l[0]=~/^(.*\/)[\w\.]*/) {$v=$1; }
    push(@l, $indexor->prompt("Url http racine ?",$v));
    push(@l, $indexor->prompt("Categorie automatique ?",1));
    my $id = $indexor->addLocalSite(@l);
    print "Url $l[0] added and account $id created\n";
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
Profondeur $depth : $nbIndexe pages indexées, $nbAjoute pages ajoutées, ".
"$nbWordsGood mots indexés, $nbWords mots lus
---------------------------------------------------------------------------\n";
	   $depth++;
	 }	
      }
    else {
	  my ($nbIndexe,$nbAjoute,$nbWords,$nbWordsGood) 
	    = $indexor->parse_new_url($parse_new);
	   print "$nbIndexe pages indexées, $nbAjoute pages ajoutées, ".
	     "$nbWordsGood mots indexés, $nbWords mots lus\n";
	 }
  }

# export data
if ($export) {$indexor->export;}

# export data for one account
if ($exportId) {$indexor->export(undef,undef,$exportId);}

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

	print "Les 10 mots les plus souvents trouvés:\n";
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
*******************************************************************************
            Circa Indexer version $Search::Circa::Indexer::VERSION

Usage: admin.pl OPTIONS

OPTIONS are:

  [+create] Create needed table for Circa
  [+drop] Drop table for Circa (All Mysql data lost !)
  [+export] Export all data in circa.sql
  [+exportId=id] Export data for account id in circa_id.sql
  [+import] Import data from circa.sql
  [+drop_id=id] Drop table for account id

  [+add=url, [email], [titre], [masque] ] : Create account for url
  [+add_site=url [,id] ] Add url in account id. If no id, 1 is used.
  [+addLocalPrompt] : Add a local account (params are asked)
  [+addLocal=file,url,email,titre,urlRacine,pathRacine,categorieAuto]

  [+parse_new=id_account] Parse and indexe url last added for account id
  [+update=nb_day,id] Update url for account id last indexed nb_day ago

  [+stats=id_account] Give some stat about account id
  [+debug=(1-4)] Verbose level

*******************************************************************************

If first time you use Circa, you can do:
$0 +create +add=http://www.monsite.com +parse_new=1 +depth_max
for index your first url.

EOF
  exit;
}
