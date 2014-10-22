package Search::Circa::Parser;

# module Circa::Parser : See Circa::Indexer
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.

# $Log: Parser.pm,v $
# Revision 1.25  2002/12/29 14:35:10  alian
# Some minor fixe suite to last update
#
# Revision 1.24  2002/12/29 03:18:37  alian
# Update POD documentation
#
# Revision 1.23  2002/12/29 00:36:30  alian
# Add undef %insite => dangerous global var ...
#
# Revision 1.22  2002/12/28 22:23:59  alian
# Some optimization after bench
#
# Revision 1.21  2002/12/28 12:36:02  alian
# Ajout phase pour ne pas analyser les mots d'un sommaire
#
# Revision 1.20  2002/12/27 12:55:43  alian
# Use ref in analyse, update stopwords
#
# Revision 1.19  2002/08/19 10:16:11  alian
# Update display of url indexed
#
# Revision 1.18  2002/08/17 18:19:02  alian
# - Minor changes to all code suite to tests

use strict;
use URI::URL;
use URI::WithBase;
use DBI;
use LWP::RobotUA;
use Carp qw/cluck/;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION 
	    %links %inside $TEXT $DESCRIPTION $KEYWORDS);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = ('$Revision: 1.25 $ ' =~ /(\d+\.\d+)/)[0];

# stopwords
my %bad = map {$_ => 1} qw (
able about above according across actually after afterwards again against ago 
all almost already also althought altogether always among amongst and another 
any anyhow anyone anything anyway anywhere apart are aren around aside away 
back because been before beforehand behind being below beneath beside besides
between beyond but came can cannot come could couldn currently did didn
directly does doing don done down downward during each easily else elsewhere
enough especially even ever every everybody everyone everything everywhere
exactly except far farther few fewer find five for formerly forth found four
frequently from full fully further generally get gets give given going gone
gonna got gotten had hardly has have having height hence her here hereafter
hereby herein hereupon hers herself him himself his hope how however
immediatly including indeed inside instead into inward isn its itself just
know largely last lately later latest least leave less lesser let lets like
liked likes likewise little lot lower made mainly make making many may maybe
means meantime meanwhile might mine more moreover most mostly mrs much must
myself namely near necessarily neither never nevertheless nine nobody none
nonetheless nor not nothing now nowhere often once one only onto other others
otherwise ought our ours ourself ourselves out outside over overall own per
perform perharps please previous previously prior probably provide providing
quickly quite rather read ready really recently require roughly said same say
see sent seven several shall shan she should shouldn simply since six slightly
some somebody somehow someone something sometime sometimes somewhat somewhere
soon still strictly such take ten than thanks that the their theirs them
themselves then thence there thereafter thereby therefore therein thereupon
these they think this those though three through thru thus thusly timely
together too took top toward towards truly two unable under unless unlike
unlikely until upon upward upwards use used using usually various very wanna
want was wasn well went were weren what whatever when whence whenever where
whereabouts whereafter whereas whereby wherefor wherein whereis whereupon
wherever whether which whichever while whither who whoever whole whom
whomever whose why will with within without worth worthy would wouldn yes
yet you your yours yourself yourselves

afin ailleurs ainsi ais ait alors aucun aucune aucunes aucuns auparavant auquel
assez aussi autour autre autres aux auxquelles avait avant avec avoir beaucoup
 bien car ceci cela celle celui cependant certain certaine certaines certains
 ces cet cette ceux chacun chacune chacunes chaque chez cinq combien comme 
comment contre dans dedans depuis des desquelles desquels deux dire dit dix 
doit donc dont duquel elle elles encore enfin entre environ est etc eux faire 
fait faut fit fut huit ici ils jamais laquelle lequel lequels les lesquelles
 lesquels leur leurs lors lorsque lui maintenant mais mes moi moins mon neuf
 non nos notre nous ont oui par parce parfois pas peu peut plus plusieurs pour
 pourquoi pourtant puis quand quant quatre que quel quelconque quelle quelles
 quelque quelquefois quelques quels qui quoi quoique sans sept ses sinon six
 soit son sont soudain sous suis sur tandis tant tel telle tels tes toi ton
 toujours tous tout toute toutes toutefois toutes trois une vers veut voici
 voir vos votre vous \$ { & com/ + www html htm file/);

#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new 
  {
    my $class = shift;
    my $self = {};
    my $indexer = shift;
    $indexer->trace(5, "Search::Circa::Parser::new\n");
    bless $self, $class;
    $self->{DBH} = $indexer->{DBH};
    $self->{ConfigMoteur} = $indexer->{ConfigMoteur};
    while (my ($n,$v)=each(%{$indexer->{ConfigMoteur}}))
	{ $indexer->trace(4, "\t$n => $v"); }
    $self->{INDEXER} = $indexer;
    # Ce module n'est presque jamais install� !
    # Evidemment cela demande une charge machine et un .so 
    # compil� pour cet environnement. Ca fait peur aux admin
    # ISP ! On encapsule donc l'appel, si on echoue, on previent que
    # tout appel au parser se soldera par une utilisation d'un parseur basic
    # sans handicaper le reste de l'application
    # Il vous reste plus qu'a faire alors une install mysql/circa en local
    # pour faire l'indexation, et exporter les resultats sur le serveur final.
    $self->{_parser_ok}=1;
    eval { require HTML::Parser };
    if ($@ || $HTML::Parser::VERSION < 3.0)
      {
	warn "Module HTML-Parser 3.0 ou superieur requis pour ".
	  "utiliser les fonctionnalit�s optimales du parser.($@)\n";
	$self->{_parser_ok}=0;
      }
    else { use HTML::Entities; }    
    $self->{INDEXER}->trace(1,"Parser::new");
    return $self;
  }

#------------------------------------------------------------------------------
# tag
#------------------------------------------------------------------------------
sub tag {
  my($tag, $num, $att) = @_; # parametre
  # Liens exterieurs
  if (($tag eq 'a') and ($$att{href})) {$links{$$att{href}}=1;}
  # Frame
  elsif (($tag eq 'frame') and ($$att{src})) {$links{$$att{src}}=1;}
  # On est dans le cas d'un meta
  elsif ($tag eq 'meta' and defined(%$att)) {
    if ($$att{name} and lc($$att{name}) eq 'description') # Description
	{$DESCRIPTION =$$att{content};}
    elsif ((lc($$att{'http-equiv'}) eq 'keywords') or
	   (lc($$att{name}) eq 'keywords'))# Mots-clefs
      {$KEYWORDS=$$att{content} ;}
  }
  # Area
  elsif (($tag eq 'area') and ($$att{href})) {$links{$$att{href}}=1;}
  $inside{$tag} += $num;   # Profondeur de la balise
}

#------------------------------------------------------------------------------
# text
#------------------------------------------------------------------------------
sub text {
  return if $inside{script} || $inside{style};
  $TEXT.=$_[0];
}

#------------------------------------------------------------------------------
# look_at
#------------------------------------------------------------------------------
sub look_at {
  my($this,$url,$idc,$idr,$lastModif,$url_local,$categorieAuto,
     $niveau,$categorie) = @_;
  undef %links; undef $TEXT; undef %inside;
  $niveau = 0 if (!$niveau);
  $categorie = 0 if (!$categorie);
  my $buf_debug = "\tUrl => $url\n\tIdc => $idc\n";
  $buf_debug.= "\tLast update => $lastModif" unless (!defined($lastModif));
  $buf_debug.= "\tUrl local => $url_local" unless (!defined($url_local));
  $this->{INDEXER}->trace(5, "Parser::look_at\n$buf_debug");
  my ($url_orig,$racineFile,$racineUrl,$lastUpdate);
  my %jt;
  my $l = \%jt;
  if ($url_local or URI->new($url)->scheme eq 'file') {$this->set_agent(1);}
  else {$this->set_agent(0);}
  if ($url_local)
    {
      $this->{ConfigMoteur}->{'temporate'}=0;
      if ($url_local=~/.*\/$/)
	{
	  chop($url_local);
	  if (-e "$url_local/index.html") {$url_local.="/index.html";}
	  elsif (-e "$url_local/index.htm") {$url_local.="/index.htm";}
	  elsif (-e "$url_local/default.htm") {$url_local.="/default.htm";}
	  else {return (-1,0,0);}
	}
      $url_orig=$url;
      $url=$url_local;
      ($racineFile,$racineUrl) = 
	$this->{INDEXER}->fetch_first("select path,url from ".
			 $this->{INDEXER}->pre_tbl."local_url where id=$idr");
    }
  my $x = 72-length($url);
  if ( $this->{inindex}) {
    print $this->{inindex},'/',$this->{toindex}," ",
      $url,($ENV{SERVER_NAME} ? "<br>\n" : (" "x$x)."\n");
  }
  my ($nb,$nbwg,$nburl)=(0,0,0);
  if ($url_local) {$this->{INDEXER}->set_host_indexed($url_local);}
  else {$this->{INDEXER}->set_host_indexed($url);}

  # Creation d'une requete
  # On passe la requete � l'agent et on attend le r�sultat
  my $res = $this->{AGENT}->request(new HTTP::Request('GET' => $url));

  if ($res->is_success)
    {
      # Langue
      my $language = $res->content_language || 'unkno';
      # Fichier non modifie depuis la derniere indexation
      if (($lastModif) && ($res->last_modified) &&
	  ($lastModif > $res->last_modified))
	{
	  print "No update on $url<br>\n" if ($this->{DEBUG});
	  $this->{INDEXER}->URL->update
	    ($idr,('id'=>$idc, 
		   'last_check'=>"NOW()"));
	  return (0,0,0);
	}
      if ($res->last_modified)
	{
	  my @date = localtime($res->last_modified);
	  $lastUpdate = ($date[5]+1900).'-'.($date[4]+1).'-'.
	    $date[3].' '.$date[2].':'.$date[1].':'.$date[0];
	}
      else {$lastUpdate='0000-00-00';}
      # Il serait judicieux de mettre ca dans le constructeur,
      # mais cela entraine 10 Mo de Ram supplementaire � 
      # l'utilisation. A voir avec les evolution du module
      # HTML::Parser
      if ($this->{_parser_ok})
	{
	  $this->{INDEXER}->trace(3,"Use HTML::Parser ...");
	  my $parser = HTML::Parser->new
	    (api_version => 3,
	     handlers => [start => [\&tag, "tagname, '+1', attr"],
			  end   => [\&tag, "tagname, '-1', attr"],
			  text  => [\&text, "dtext"],
			 ],
	     marked_sections => 1);
	  # parse du fichier
	  $parser->parse($res->content)
	    || print STDERR "Can't parse ".$res->content."::$!\n"; 
	}
      else
	{
	  $this->{INDEXER}->trace(1,"Use a basic parser ...");
	  $TEXT = $res->content;
	  $TEXT=~s{ <! (.*?) (--.*?--\s*)+(.*?)> } 
	          {if ($1 || $3) {"<!$1 $3>";} }gesx;
	  $TEXT=~s{ <(?: [^>\'\"] * | ".*?" | '.*?' ) + > }{}gsx;
	  $TEXT=decode_entities($TEXT);
	}

      # Mots clefs et description
      my ($desc,$keyword)=($DESCRIPTION||' ',$KEYWORDS||' ');
     undef $DESCRIPTION; undef $KEYWORDS; 
      my $titre = $res->title || $url;# Titre
      # Categorie
      if ($categorieAuto) 
	  {$categorie = $this->{INDEXER}->categorie->get($url,$idr);}
      if (!$categorie) {$categorie=0;}
      # Mis a jour de l'url
      if ($this->{INDEXER}->URL->update
	    ($idr,
	     (parse        => 1,
		id           => $idc,
		titre        => $titre,
		description  => $desc,
		last_update  => $lastUpdate,
		last_check   => 'NOW()',
		langue       => $language,
		categorie    => $categorie
	     )
	    )) { $this->{INDEXER}->trace(2, "$url mis � jour avec success"); }

      # Traitement des mots trouves
      $l=analyse($keyword,$this->{ConfigMoteur}->{'facteur_keyword'},$l);
      $l=analyse($desc,$this->{ConfigMoteur}->{'facteur_description'},$l);
      $l=analyse($titre,$this->{ConfigMoteur}->{'facteur_titre'},$l);
      $l=analyse($TEXT,$this->{ConfigMoteur}->{'facteur_full_text'},$l);
      $l=analyse($url,$this->{ConfigMoteur}->{'facteur_url'},$l);
      $this->{INDEXER}->dbh->do
	("delete from ".$this->{INDEXER}->pre_tbl.$idr."relation ".
		       "where id_site = $idc");
      undef $TEXT;

      # Chaque mot trouve plus de $ConfigMoteur{'nb_min_mots'} fois
      # est enregistre
      # On passe cette etape si le nombre de liens de la page est superieur
      # a 50% le nombre de mots retenus, il s'agit alors
      # d'un sommaire peut interessant � consulter
      my $nbw = 0;
      if (scalar keys %links < (( scalar keys %$l) * 0.5)) {
	while (my ($mot,$nb)=each(%$l)) {
	  next if (!$nb or $nb < $this->{'ConfigMoteur'}->{'nb_min_mots'});
	  my $requete = "insert into ".
	    $this->{INDEXER}->pre_tbl.$idr.
	        "relation (mot,id_site,facteur) ".
		"values ('$mot',$idc,$nb)";
	  $this->{INDEXER}->dbh->do($requete) && $nbwg++;
	  $this->{INDEXER}->trace(3,"\t\tStore words: ".$requete);
	}
	$nbw=keys %$l;
      }
      else {
 	$this->{INDEXER}->trace
	  (1,"Sommaire - ".(scalar keys %$l).
	     " mots ignores pour ".(scalar keys %links)." liens");
      }

      # On n'indexe pas les liens si on est au niveau max
      if ($niveau == $this->{ConfigMoteur}{'niveau_max'}) {
	$this->{INDEXER}->trace(1,"Niveau max atteint. Liens suivants de ". 
				"cette page ignor�s<br>");
	return (0,0,0);
      }
      # Traitement des url trouves
      my $base = $res->base;
      my @l = keys %links; undef %links;
	$this->{INDEXER}->trace(2, "Liens trouv�s") if ($#l>0);
      foreach my $var (@l) {
	$var = url($var,$base)->abs; # Url absolu
	$var = $this->check_links('a',$var);
	if (($url_local) && ($var)) {
	  my $urlb = $var;
	  $urlb=~s/$racineFile/$racineUrl/g;
	  #print h1("Ajout site local:$$var[2] pour $racineFile");
	  $this->{INDEXER}->trace(2, "\t".$urlb);
	  if ($this->{INDEXER}->URL->add
	      ($idr,
	       (url       => $urlb, 
		urllocal  => $var,
		niveau    => $niveau+1,
		categorie => $categorie,
		valide    => 1,
		browse_categorie=>$categorieAuto)))
	    { $nburl++; }
	  else {$this->{INDEXER}->trace
		  (2,"\tCan't add $urlb:\n\t$DBI::errstr");}
	}
	elsif ($var) {
	  $this->{INDEXER}->trace(2, "\t".$var);
	  if ($this->{INDEXER}->URL->add
	      ($idr,
	       (url       => $var,
		niveau    => $niveau+1,
		categorie => $categorie,
		valide => 1)))
	    { $nburl++; }
	  else 
	    { $this->{INDEXER}->trace
		(2,"\tCan't add $var:\n\t$DBI::errstr");}
	}
      }
      $this->{INDEXER}->trace(3, "---------------------------------\n");
      return ($nburl,$nbw,$nbwg);
    }
  # Sinon previent que URL defectueuse
  else { print "*** ", $res->code," : $url\n";return (-1,0,0);}
}

#------------------------------------------------------------------------------
# set_agent
#------------------------------------------------------------------------------
sub set_agent
  {
  my ($self,$locale)=@_;
  $self->{INDEXER}->trace(5, "Circa::Parser::set_agent $locale\n");
  return if ($self->{AGENT} && $self->{_ROBOT}==$locale); # agent already set
  $self->{_ROBOT}=$locale;
  if (($self->{ConfigMoteur}->{'temporate'}) && (!$locale)) {
    $self->{'AGENT'} = LWP::RobotUA->new
      ("CircaParser $VERSION",$self->{'ConfigMoteur'}->{'author'});
    $self->{AGENT}->delay(1/120.0);
  }
  else {$self->{AGENT} = new LWP::UserAgent; }
  if ($self->{PROXY}) {$self->{AGENT}->proxy(['http', 'ftp'], $self->{PROXY});}
  $self->{AGENT}->max_size($self->{INDEXER}->size_max) 
    if ($self->{INDEXER}->size_max);
  $self->{AGENT}->timeout(25); # Set timeout to 25s (defaut 180)
}

#------------------------------------------------------------------------------
# analyse
#------------------------------------------------------------------------------
sub analyse  {
  my $data = shift;
  my $facteur = shift;
  return if (!@_);
  my ($l,$e);
  if (ref($_[0])) { $l= shift; }
  else {my %l; cluck "What's that ?";%l = @_; $l=\%l; }
  return $l if (!$data or !$facteur);
  # Ponctuation et mots recurents
  $data=~s/http:\/\// /gm;
  $data=~tr/\n\t<>.;:,?!()\"\'[]#=\/_/ /;
  $data=~s/\s+/ /gm;
  foreach (split(/\s/,$data)) {
    next if !$_;
    $e=lc($_);
    $$l{$e}+=$facteur
      if (($e =~/\w/)&&(length($e)>2)&&(!$bad{$e})&&($e !~/^\d*$/));
  }
  return $l;
}

#------------------------------------------------------------------------------
# check_links
#------------------------------------------------------------------------------
sub check_links
  {
    my($self,$tag,$links) = @_;
    my $host = $self->{INDEXER}->host_indexed;
    my $li = "doc|zip|ps|gif|jpg|gz|pdf|eps|png|deb|xls|ppt|".
	     "class|GIF|css|js|wav|mid";
    my $bad = qr/\.($li)$/i;
    if (($tag) && ($links) && ($tag eq 'a') 
	&& ($links=~/\Q$host\E/) 
	&& ($links !~ $bad))
    {
      if ($links=~/^(.*?)#/) {$links=$1;} # Don't add anchor
      if ((!$self->{ConfigMoteur}->{'indexCgi'})&&($links=~/^(.*?)\?/)) 
	  {$links=$1;}
      return $links;
    }
   return 0;
  }


#------------------------------------------------------------------------------
# POD DOCUMENTATION
#------------------------------------------------------------------------------

=head1 NAME

Search::Circa::Parser - provide functions to parse HTML pages by Circa

=head1 SYNOPSIS

      use Search::Circa::Indexer;
      my $index = new Search::Circa::Indexer;
      $index->connect(...);
      $index->Parser->look_at($url,account);

=head1 DESCRIPTION

This module use HTML::Parser facilities. It's call by Search::Circa::Indexer
for index each document. Main method is C<look_at>.

=head1 Public Class Interface

=over

=item B<new> I<Search::Circa::Indexer object>

Create a new Circa::Parser object with indexer instance properties

=item B<look_at> I<url, idc, idr, lastModif, url_local,
                categorieAuto, niveau, categorie>

Index an url. Job done is:

=over

=item *

Test if url used is valid. Return -1 else

=item *

Get the page and add each words found with weight set in constructor.

=item *

If maximum level of links is not reach, add each link found for the next 
indexation

=back

Parameters:

=over

=item *

$url : Url to read

=item *

$idc: Id of url in table links

=item *

$idr : Id of account's url

=item *

$lastModif (optional) : If this parameter is set, Circa didn't make any job
on this page if it's older that the date.

=item *

$url_local (optional) Local url to reach the file

=item *

$categorieAuto (optional) If $categorieAuto set to true, Circa will
create/set the category of url with syntax of directory found. Ex:

http://www.alianwebserver.com/societe/stvalentin/index.html will create
and set the category for this url to Societe / StValentin

If $categorieAuto set to false, $categorie will be used.

=item *

$niveau (optional) Level of actual link.

=item *

$categorie (optional) See $categorieAuto.

=back

Return (-1,0) if url isn't valide, number of word and number of links  
found else

=item B<set_agent> I<local>

Set user agent for Circa robot. If local is set to 0 or
$self->{ConfigMoteur}->{'temporate'}==0,
LWP::UserAgent will be used. Else LWP::RobotUA is used.

=item B<analyse> I<data, facteur, ref_hash>

Split data in words, and put in in %$ref_hash with score
Hash structure is ('mots'=>facteur).

=over

=item *

data : buffer � analyser

=item *

$facteur : facteur � attribuer � chacun des mots trouv�s

=item *

%l : Tableau associatif o� est rang� le r�sultat

=back

Return ref_hash

=item B<tag>

Method call for each HTML tag find in HTML pages.

=item B<text>

Method call for each content of tag in HTML pages

=item B<check_links> I<tag, links>

Check if url $links will be add to Circa. Url must begin with 
$self->host_indexed, and his extension must be not doc,zip,ps,gif,jpg,gz,
pdf,eps,png,deb,xls,ppt,class,GIF,css,js,wav,mid.

If $links is accepted, return url. Else return 0.

=back

=head1 VERSION

$Revision: 1.25 $

=head1 SEE ALSO

L<Search::Circa::Indexer>

=head1 AUTHOR

Alain BARBET alian@alianwebserver.com

=cut
