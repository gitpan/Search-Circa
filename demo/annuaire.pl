#!/usr/bin/perl -w
#
# Simple perl example to interface with module Circa::Indexer
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.
#
# $Date: 2001/10/27 21:34:20 $
# $Log: annuaire.pl,v $
# Revision 1.2  2001/10/27 21:34:20  alian
# - first release
#

use diagnostics;
use strict;
use CircaConf;
use lib $CircaConf::CircaDir;
use Search::Circa::Annuaire;
use Getopt::Long;

my $annuaire = new Search::Circa::Annuaire (%CircaConf::conf);
if (!$annuaire->connect($CircaConf::User,
				$CircaConf::Password,
				$CircaConf::Database,
				$CircaConf::Host))
  {die "Erreur à la connection MySQL:$DBI::errstr\n";}
my $rep = $annuaire->prompt("Where I can build pages ?",
				    "/tmp/annuaire"); 
$annuaire->create_annuaire(1, $CircaConf::TemplateDir."circa.htm",$rep);
$annuaire->close;
