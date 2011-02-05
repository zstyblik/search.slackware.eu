#!/usr/bin/perl
# 2010/Mar/16 @ Zdenek Styblik
# desc: Fix Slackware's package's MD5s
use lib "/srv/httpd/search.slackware.eu/perl/";
use Slackware::Search::ConfigParser qw(_getConfig);
use Slackware::Search::SupportLib qw(:T1);

use DBI;
use strict;
use warnings;

use constant CFGFILE => '/srv/httpd/search.slackware.eu/conf/config.pl';

my $cfgParser = 'Slackware::Search::ConfigParser';
my %CFG = $cfgParser->_getConfig(CFGFILE);

unless (%CFG || keys(%CFG)) {
	printf("Parsing of config file has failed.\n");
	exit 2;
}

my $dbh = DBI->connect($CFG{DB_DSN},
$CFG{DB_USER},
$CFG{DB_PASS},
	{
		AutoCommit => 0, 
		RaiseError => 1, 
		PrintError => 1
	}
);

die ("Unable to connect to DB.") unless ($dbh);

### MAIN ###
my $numArgs = $#ARGV + 1;

if ($numArgs == 0) {
	print "Parameter must be Slackware version.\n";
	exit 1;
}

if ($ARGV[0] !~ /^slackware(64)?-([0-9]+\.[0-9]+|current){1}$/i) {
	print "Parameter doesn't look like Slackware version to me."
	.$ARGV[0]."\n";
	exit 1;
}

my $slib = 'Slackware::Search::SupportLib';
$slib->_set_dbHandler($dbh);

my $sverExists = $slib->existsSlackVer($ARGV[0]);
if ($sverExists == 0) {
	print "This Slackware version is not in DB.\n";
	print "Please use add script.\n";
	exit 1;
}
my $idSlackVer = 0;
$idSlackVer = $slib->getSlackVerId($ARGV[0]);
$slib->_set_sverName($ARGV[0]);

### MANIFEST.bz2 ###
# DELETED
### PKGS MD5 ###
my $categoryLast = '';
my $idCatLast = 0;
my $idSerie = 0;
my $idSerieLast = 0;
my $serieLast = '';
open(FPKGS5, "./CHECKSUMS.md5.pkgs")
        or die("Unable to open CHECKSUMS.md5.pkgs");
printf("Processing package's MD5s...\n");
# TODO - small problem here is what IF new manifest gets added
while (my $linePkg5 = <FPKGS5>) {
        chomp($linePkg5);
        my @arrLine = split(' ', $linePkg5);
        if ($arrLine[1] !~ /^\.\// || $arrLine[1] !~ /\.(tgz|txz)$/) {
                next;
        } # unless $arrLine
        $arrLine[1] = substr($arrLine[1], 2);
        my @arrPath = split('/', $arrLine[1]);

        my $pkgName = pop(@arrPath);
        
        my $idPkg = $slib->getPkgId($pkgName);

        my $category = shift(@arrPath);
        my $idCategory = 0;
        if ($category eq $categoryLast) {
                $idCategory = $idCatLast;
        } else {
                $idCategory = $slib->getCategoryId($category);
                $idCatLast = $idCategory;
                $categoryLast = $category;
        }

        my $serie = '';
        for my $entry (@arrPath) {
                $serie.= $entry;
        }
        unless ($serie) {
                $idSerie = 'NULL';
        } else {
                if ($serie eq $serieLast) {
                        $idSerie = $idSerieLast;
                } else {
                        $idSerie = $slib->getSerieId($serie);
                        $idSerieLast = $idSerie;
                        $serieLast = $serie;
                }
        }
        my $sql200 = sprintf("UPDATE packages SET package_md5sum = '%s' WHERE 
                id_slackversion = %i AND id_category = %i AND id_serie = %s AND 
        id_package = %i;", $arrLine[0], $idSlackVer, $idCategory, $idSerie, $idPkg);
        $dbh->do($sql200)
                or die("Unable to update package's MD5 sum.");
} # while my $linePkg5
close(FPKGS5);
### PACKAGES.TXT ###
# DELETED
$dbh->commit;
$dbh->disconnect;

