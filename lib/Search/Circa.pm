package Search::Circa;

# module Circa: provide general method for Circa
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.

use DBI;
use DBI::DBD;
use CircaConf;
use Search::Circa::Categorie;
use Search::Circa::Url;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = ('$Revision: 1.14 $ ' =~ /(\d+\.\d+)/)[0];

#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new 
  {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->{DBH} = undef;
    $self->{PREFIX_TABLE} = 'circa_';
    $self->{SERVER_PORT}  ="3306";   # Port de mysql par default
    $self->{DEBUG} = 0;
    return $self;
  }

#------------------------------------------------------------------------------
# port_mysql
#------------------------------------------------------------------------------
sub port_mysql
  {
  my $self = shift;
  if (@_) {$self->{SERVER_PORT}=shift;}
  return $self->{SERVER_PORT};
  }

#------------------------------------------------------------------------------
# pre_tbl
#------------------------------------------------------------------------------
sub pre_tbl
  {
  my $self = shift;
  if (@_) {$self->{PREFIX_TABLE}=shift;}
  return $self->{PREFIX_TABLE};
  }

#------------------------------------------------------------------------------
# connect
#------------------------------------------------------------------------------
sub connect  {
  my ($this,$user,$password,$db,$server)=@_;
  if (!$user and !$password and !$db and !$server) {
    $user     = $this->{_USER}     || $CircaConf::User;
    $password = $this->{_PASSWORD} || $CircaConf::Password;
    $db       = $this->{_DB}       || $CircaConf::Database;
    $server   = $this->{_HOST}     || $CircaConf::Host;
  }
  $server = '127.0.0.1' if (!$server);
  my $driver = "DBI:mysql:database=$db;host=$server;port=".$this->port_mysql;
  $this->{_DB}=$db; $this->{_PASSWORD}=$password; $this->{_USER}=$user;
  $this->{_HOST}=$server;
  $this->{DBH} = DBI->connect($driver,$user,$password,{ PrintError => 0 }) 
    || return 0;
  return 1;
}

#------------------------------------------------------------------------------
# close
#------------------------------------------------------------------------------
sub close {$_[0]->{DBH}->disconnect;}

#------------------------------------------------------------------------------
# dbh
#------------------------------------------------------------------------------
sub dbh { return $_[0]->{DBH};}

#------------------------------------------------------------------------------
# categorie
#------------------------------------------------------------------------------
sub categorie {return new Search::Circa::Categorie($_[0]);}

#------------------------------------------------------------------------------
# URL
#------------------------------------------------------------------------------
sub URL {return new Search::Circa::Url($_[0]);}

#------------------------------------------------------------------------------
# start_classic_html
#------------------------------------------------------------------------------
sub start_classic_html
  { 
    my ($self,$cgi)=@_;
    return $cgi->start_html
	( -'title'  => 'Circa',
	  -'author' => 'alian@alianwebserver.com',
	  -'meta'   => {'keywords'  => 'circa,recherche,annuaire,moteur',
			    -'copyright'=> 'copyright 1997-2000 AlianWebServer'},
	  -'style'  => {'src' => "circa.css"},
	  -'dtd'    => '-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd')."\n";
  }

#------------------------------------------------------------------------------
# trace
#------------------------------------------------------------------------------
sub trace  {
  my ($self, $level, $msg)=@_;
  if ($self->{DEBUG} >= $level) { 
    if ($ENV{SERVER_NAME}) {
      print STDERR $msg,"\n"; }
    else { $msg,"\n"; }
  }
}

#------------------------------------------------------------------------------
# header
#------------------------------------------------------------------------------
sub header {return "Content-Type: text/html\n\n";}


#------------------------------------------------------------------------------
# fill_template
#------------------------------------------------------------------------------
sub fill_template
  {
  my ($self,$masque,$vars)=@_;
  open(FILE,$masque) || die "Can't read $masque<br>";
  my @buf=<FILE>;
  CORE::close(FILE);
  while (my ($n,$v)=each(%$vars))
    {
    if ($v) {map {s/<\? \$$n \?>/$v/gm} @buf;}
    else {map {s/<\? \$$n \?>//gm} @buf;}
    }
  return join('',@buf);
  }

#------------------------------------------------------------------------------
# fetch_first
#------------------------------------------------------------------------------
sub fetch_first
  {
  my ($self,$requete)=@_;
  my $sth = $self->{DBH}->prepare($requete);
  my @row;
  if ($sth->execute) {
    # Pour chaque categorie
    @row = $sth->fetchrow_array;
    $sth->finish;
  } else { $self->trace(1,"Erreur:$requete:$DBI::errstr<br>"); }
  if (wantarray()) { return @row; }
  else { return $row[0]; }
  }

#------------------------------------------------------------------------------
# appartient
#------------------------------------------------------------------------------
sub appartient
  {
  my ($self,$elem,@liste)=@_;
  return 0 unless $elem;
  foreach (@liste) {return 1 if ($_ and $_ eq $elem);}
  return 0;
  }

#------------------------------------------------------------------------------
# prompt
#------------------------------------------------------------------------------
sub prompt
  {
    my($self,$mess,$def)=@_;
    my $ISA_TTY = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;
    Carp::confess("prompt function called without an argument") 
	  unless defined $mess;
    my $dispdef = defined $def ? "[$def] " : " ";
    $def = defined $def ? $def : "";
    my $ans;
    local $|=1;
    print "$mess $dispdef";
    if ($ISA_TTY) { chomp($ans = <STDIN>); }
    else { print "$def\n"; }
    return ($ans ne '') ? $ans : $def;
  }

#------------------------------------------------------------------------------
# POD DOCUMENTATION
#------------------------------------------------------------------------------

=head1 NAME

Circa - a Search Engine/Indexer running with Mysql

=head1 DESCRIPTION

This is Search::Circa, a module who provide functions to
perform search on Circa, a www search engine running with
Mysql. Circa is for your Web site, or for a list of sites.
It indexes like Altavista does. It can read, add and
parse all url's found in a page. It add url and word
to MySQL for use it at search.

Circa can be used for index 100 to 100 000 url

Notes:

=over

=item *

Accents are removed on search and when indexed

=item *

Search are case unsensitive (mmmh what my english ? ;-)

=back

Search::Circa::Search work with Search::Circa::Indexer result. 
Search::Circa::Search is a Perl interface, but it's exist on 
this package a PHP client too.

Search::Circa is root class for Search::Circa::Indexer and 
Search::Circa::Search.

=head1 SYNOPSIS

See L<Search::Circa::Search>, L<Search::Circa::Indexer>

=head1 FREQUENTLY ASKED QUESTIONS

Q: Where are clients for example ?

A: See in demo directory. For command line, see *.pl file, for CGI, take
a look in cgi-bin/

Q: Where are global parameters to connect to Circa ?

A: Use lib/CircaConf.pm file

Q : What is an account for Circa ?

A: It's like a project, or a databse. A namespace for what you want.

Q : How I begin with indexer ?

A: May be something like this: 

   $ circa_admin +create +add=http://monsite.com +parse_new=1 +depth_max

Q : Did you succed to use Circa with mod_perl ?

A: Yes

=head1 SEE ALSO

L<Search::Circa::Indexer> : Indexer module

L<Search::Circa::Search> : Searcher module

L<Search::Circa::Annuaire> : Manage directory of Circa

L<Search::Circa::Url> : Manage url of Circa

L<Search::Circa::Categorie> : Manage categorie of Circa

L<Search::Circa::Parser> : Manage Parser of Indexer

=head1 Public interface

You use this method behind Search::Circa::Indexer and 
Search::Circa::Search object

=over

=item connect($user, $password, $db, $host)

Connect Circa to MySQL. Return 1 on succes, 0 else

=over

=item *

$user     : Utilisateur MySQL

=item *

$password : Mot de passe MySQL

=item *

$db       : Database MySQL

=item *

$bost   : Adr IP du serveur MySQL

=back

Connect Circa to MySQL. Return 1 on succes, 0 else

=item close

Close connection to MySQL

=item pre_tbl

Get or set the prefix for table name for use Circa with more than one
time on a same database

=item fill_template($masque,$vars)

 $masque : Path of template
 $vars : hash ref with keys/val to substitue

Give template with remplaced variables
Ex: if $$vars{age}=12, and $masque have

  J'ai <? $age ?> ans,

this function give:

  J'ai 12 ans,

=item fetch_first($requete)

Execute request SQL on db and return first row. In list context, retun full 
row, else return just first column.

=item trace($level, $msg)

Print message $msg on standart input if debug level for script is upper than
$level

=item prompt($message, $default_value)

Ask in STDIN for a parameter and return value

=back

=head1 AUTHOR

Alain BARBET alian@alianwebserver.com

=cut

1;
