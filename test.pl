# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $n = 1;

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok $n\n" unless $loaded;}

use Search::Circa;
$loaded=1;
print "ok ",$n++,"\n";

$loaded=0;
use Search::Circa::Indexer;
$loaded=1;
print "ok ",$n++,"\n";

$loaded=0;
use Search::Circa::Search;
$loaded=1;
print "ok ",$n++,"\n";

$loaded=0;
use Search::Circa::Url;
$loaded=1;
print "ok ",$n++,"\n";

$loaded=0;
use Search::Circa::Parser;
$loaded=1;
print "ok ",$n++,"\n";

$loaded=0;
use Search::Circa::Categorie;
$loaded=1;
print "ok ",$n++,"\n";

$loaded=0;
use Search::Circa::Annuaire;
$loaded=1;
print "ok ",$n++,"\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub check_url
  {
    my %url =
	{
	 'url'              => 'http://localhost',
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
	 'parse'            => 0
	};
    $url{'id'} = $circa->url->save(%url);
    if (!$url{'id'}) { print "not ok 8\n"; }
    else { print "ok 8\n" }
    $url{'niveau'} = 1;
    if (!$circa->url->update(%url)) { print "not ok 9\n"; }
    else { print "ok 9\n"; }
#    if ($circa->url->load($url{'id'}))
  }
