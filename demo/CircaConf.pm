package CircaConf;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = ('$Revision: 1.3 $ ' =~ /(\d+\.\d+)/)[0];

#-------- A MODIFIER --------#

# Utilisateur Mysql
$CircaConf::User     = "alian";

# Password Mysql
$CircaConf::Password = "";

# Adresse DNS du serveur DNS
$CircaConf::Host     = "localhost";

# Nom de la base de donn�e
$CircaConf::Database = "circa";

# Repertoire des masques HTML
$CircaConf::TemplateDir = "/home/alian/project/CPAN/Search/Circa/demo/ecrans/";

# Repertoire ou creer / lire les fichier d'export / import
# (droit en ecriture pour user apache necessaire si export en mode cgi)
$CircaConf::export = "/home/alian/tmp";

# Repertoire des librairies de Circa si non installe par root
$CircaConf::CircaDir = "/home/alian/circa";

# Fin
