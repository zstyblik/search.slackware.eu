#!/usr/bin/perl
# 2009/Mar/01 @ Zdenek Styblik
# Desc: add new version of Slackware into DB and everything 
# that belongs to it.
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

my @filesReq = qw(CHECKSUMS.md5 CHECKSUMS.md5.files 
CHECKSUMS.md5.pkgs FILELIST.TXT FILELIST.TXT.files 
FILELIST.TXT.md5 FILELIST.TXT.pkgs);
for my $fileReq (@filesReq) {
	unless ( -e "./$fileReq" ) {
		print "File $fileReq doesn't seem to exist.\n";
		exit 1;
	} # unless -e $fileReq
} # for my $fileReq

my $slib = 'Slackware::Search::SupportLib';
$slib->_set_dbHandler($dbh);

my $sverExists = $slib->existsSlackVer($ARGV[0]);
if ($sverExists == 1) {
	print "This Slackware version is already in DB.\n";
	print "Please use update script.\n";
	exit 1;
}
my $idSlackVer = -1;
$idSlackVer = $slib->insertSlackVer($ARGV[0]);
$slib->_set_sverName($ARGV[0]);

### PKGS ###
open(FPKGS, "./FILELIST.TXT.pkgs")
	or die("Unable to open FILELIST.TXT.pkgs");

print "Processing packages...\n";
my $categoryLast = '';
my $idSerieLast = -1;
my $idCatLast = -1;
my $serieLast = '';
my $idSerie;
while (my $linePkg = <FPKGS>) {
	chomp($linePkg);
	my @arrLine = split(' ', $linePkg);
	unless ($arrLine[7]) {
		next;
	} # unless $arrLine[7]
# 4 - size; 5 - date; 6 - time; 7 pkgname
	if ($arrLine[7] !~ /^\.\// || $arrLine[7] !~ /\.(tgz|txz)$/) {
		next;
	} # if $arrLine[7]
	$arrLine[7] = substr($arrLine[7], 2);
	my @arrPath = split(/\//, $arrLine[7]);

	my $pkgName = pop(@arrPath);
	my $idPkg = $slib->insertPkg($pkgName);

	my $category = shift(@arrPath);
	my $idCategory = 0;
	if ($category eq $categoryLast) {
		$idCategory = $idCatLast;
	} else {
		$idCategory = $slib->insertCategory($category);
		$idCatLast = $idCategory;
		$categoryLast = $category;
	}

	my $serie = join("/", @arrPath);
#	for my $entry (@arrPath) {
#		$serie.= $entry;
#	}
	unless ($serie) {
		$idSerie = 'NULL';
	} else {
		if ($serie eq $serieLast) {
			$idSerie = $idSerieLast;
		} else {
			$idSerie = $slib->insertSerie($serie);
			$idSerieLast = $idSerie;
			$serieLast = $serie;
		}
	}

	my $sql1 = "INSERT INTO packages (id_slackversion, id_category, 
	id_serie, id_package, package_size, package_created) 
	VALUES ($idSlackVer, $idCategory, $idSerie,
	$idPkg, ".$arrLine[4].", '".$arrLine[5]." ".$arrLine[6]."');";
	$dbh->do($sql1)
		or die("Unable to insert package.");
} # while my $linePkg

close(FPKGS);

### PKGS MD5 ###
open(FPKGS5, "./CHECKSUMS.md5.pkgs")
	or die("Unable to open CHECKSUMS.md5.pkgs");

print "Processing package's MD5s...\n";
while (my $linePkg5 = <FPKGS5>) {
	chomp($linePkg5);
	my @arrLine = split(' ', $linePkg5);
	if ($arrLine[1] !~ /^\.\// || $arrLine[1] !~ /\.(tgz|txz)$/) {
		next;
	} # unless $arrLine
	$arrLine[1] = substr($arrLine[1], 2);
	my @arrPath = split(/\//, $arrLine[1]);

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

	my $sql1 = "UPDATE packages SET package_md5sum = '".$arrLine[0]
	."' WHERE id_slackversion = $idSlackVer AND 
	id_category = $idCategory AND id_serie = $idSerie AND 
	id_package = $idPkg;";
	$dbh->do($sql1)
		or die("Unable to update package's MD5 sum.");
} # while my $linePkg5

close(FPKGS5);

### SVER DATA FILES ###
open(DFILE, "./FILELIST.TXT.files")
	or die("Unable to open FILELIST.TXT.files.");

print "Processing data files (pkg desc'n files)...\n";
print "This is going to take a while...\n";

while (my $lineDF = <DFILE>) {
	chomp($lineDF);
	my @arrLine = split(' ', $lineDF);
	unless ($arrLine[7]) {
		next;
	}
	if ($arrLine[7] !~ /^\.\// || $arrLine[7] =~ /\.md5$/) {
		next;
	}
	if ($arrLine[7] =~ /\.txt$/i) {
		$slib->processPkgDesc($arrLine[7], $idSlackVer);
	}
	if ($arrLine[7] =~ /\.bz2$/i) {
		$slib->processManifestFile($arrLine[7], $idSlackVer);
	}
	my $sql1 = "INSERT INTO datafile (id_slackversion, fpath, 
	dfile_created) VALUES ($idSlackVer, '".$arrLine[7]."', '".
	$arrLine[5]." ".$arrLine[6]."');";
	$dbh->do($sql1) or die("Unable to insert datafile.");
} # while my $lineDF

close(DFILE);

### SVER DATA FILES MD5 ###
open(DFILE5, "./CHECKSUMS.md5.files")
	or die("Unable to open CHECKSUMS.md5.files");
while (my $lineDF5 = <DFILE5>) {
	chomp($lineDF5);
	my @arrLine = split(' ', $lineDF5);
	unless ($arrLine[1]) {
		next;
	}
	if ($arrLine[1] !~ /^\.\//) {
		next;
	}
	my $sql1 = "UPDATE datafile SET dfile_md5sum = '".$arrLine[0]."' 
	WHERE fpath = '".$arrLine[1]."' AND 
	id_slackversion = $idSlackVer;";
	$dbh->do($sql1) or die("Unable to update datafile's MD5 sum.");
} # while my $lineDF5

close(DFILE5);

### Update pkgs count ;;; No. files is being updated from ex.script;
# TODO - this needs to be rewritten
my $sql999 = "UPDATE slackversion SET no_pkgs = (SELECT COUNT(*) \
FROM view_packages WHERE id_slackversion = $idSlackVer) WHERE \
id_slackversion = $idSlackVer;";
$dbh->do($sql999);

$dbh->commit;
$dbh->disconnect;
print "\n";

