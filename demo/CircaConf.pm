package CircaConf;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = ('$Revision: 1.4 $ ' =~ /(\d+\.\d+)/)[0];

#-------- A MODIFIER --------#

# Utilisateur Mysql
$CircaConf::User     = "alian";

# Password Mysql
$CircaConf::Password = "";

# Adresse DNS du serveur DNS
$CircaConf::Host     = "localhost";

# Nom de la base de donnée
$CircaConf::Database = "circa";

# Repertoire des masques HTML
$CircaConf::TemplateDir = "/home/alian/project/CPAN/Search/Circa/demo/ecrans/";

# Repertoire ou creer / lire les fichier d'export / import
# (droit en ecriture pour user apache necessaire si export en mode cgi)
$CircaConf::export = "/home/alian/tmp";

# Repertoire des librairies de Circa si non installe par root
$CircaConf::CircaDir = "/home/alian/circa";

# some values ...
%CircaConf::conf=
  (
   'author'            => 'circa@alianwebserver.com', # Responsable du moteur
   'temporate'         => 0,  # Temporise les requetes sur le serveur de 8s.
   'facteur_keyword'   => 15, # <meta name="KeyWords"
   'facteur_description'  => 10, # <meta name="description"
   'facteur_titre'     => 10, # <title></title>
   'facteur_full_text' => 1,  # reste
   'facteur_url'       => 10,
   'nb_min_mots'       => 2,  # facteur min pour garder un mot
   'niveau_max'        => 7,  # Niveau max à indexer
   'indexCgi'          => 0  # follow link for CGI (ex: ?nom=toto&riri=eieiei
   );
# Fin
