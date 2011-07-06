#!/usr/bin/perl
# 2010/Mar/16 @ Zdenek Styblik
# desc: Update Slackware packages, descriptions, files and whatever
use lib "/mnt/search.slackware.eu/perl/";
use Slackware::Search::ConfigParser qw(_getConfig);
use Slackware::Search::SupportLib qw(:T1);

use DBI;
use strict;
use warnings;

use constant CFGFILE => '/mnt/search.slackware.eu/conf/config.pl';

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
	print("Parameter must be Slackware version.\n");
	exit 1;
}

if ($ARGV[0] !~ /^slackware(64)?-([0-9]+\.[0-9]+|current){1}$/i) {
	printf("Parameter '%s' doesn't look like Slackware version to me.\n", 
		$ARGV[0]);
	exit 1;
}

my @filesReq = qw(CHECKSUMS.md5.pkgs.diff CHECKSUMS.md5.files.diff
FILELIST.TXT.pkgs CHECKSUMS.md5.pkgs FILELIST.TXT.files.desc 
CHECKSUMS.md5.files);
for my $fileReq (@filesReq) {
	unless ( -e "./$fileReq" ) {
		printf("File '%s' doesn't seem to exist.\n", $fileReq);
		exit 1;
	} # unless -e $fileReq
} # for my $fileReq

my $slib = 'Slackware::Search::SupportLib';
$slib->_set_dbHandler($dbh);

my $sverExists = $slib->existsSlackVer($ARGV[0]);
if ($sverExists == 0) {
	printf("This Slackware version is not in DB.\n");
	printf("Please use add script.\n");
	exit 1;
}
my $idSlackVer = 0;
$idSlackVer = $slib->getSlackVerId($ARGV[0]);
$slib->_set_sverName($ARGV[0]);

my (%pkgsAdd, %pkgsDel, %pkgsMod) = ();
open(FPKGD, './CHECKSUMS.md5.pkgs.diff') 
	or die("Unable to open CHECKSUMS.md5.pkgs.diff");
while (my $line = <FPKGD>) {
	chomp($line);
	my @arr = split(' ', $line);
	if ($arr[0] eq 'A') {
		$pkgsAdd{$arr[1]} = 'A';
		next;
	}
	if ($arr[0] eq 'D') {
		$pkgsDel{$arr[1]} = 'D';
		next;
	}
	if ($arr[0] eq 'M') {
		$pkgsMod{$arr[1]} = 'M';
		next;
	}
}
close(FPKGD);

my (%fileAdd, %fileDel, %fileMod) = ();
open(FFILED, './CHECKSUMS.md5.files.diff') 
	or die("Unable to open CHECKSUMS.md5.files.diff");
while (my $lineFile = <FFILED>) {
	chomp($lineFile);
	my @arrFile = split(' ', $lineFile);
	if ($arrFile[0] eq 'A') {
		$fileAdd{$arrFile[1]} = 'A';
		next;
	}
	if ($arrFile[0] eq 'D') {
		$fileDel{$arrFile[1]} = 'D';
		next;
	}
	if ($arrFile[0] eq 'M') {
		$fileMod{$arrFile[1]} = 'M';
		next;
	}
}
close(FFILED);

### PKGS DEL ###
my @pkgsDel = keys(%pkgsDel);
unless (@pkgsDel == 0) {
	printf("Removing old packages...\n");
	my $categoryLast = '';
	my $idSerieLast = 0;
	my $idCatLast = 0;
	my $serieLast = '';
	my $idSerie;
	my $batchFile = $slib->_get_batchFile;
	# ToDo - this file shouldn't exist and if so, though luck.
	open(FBATCH, ">".$batchFile."-".$ARGV[0]) 
		or die("Unable to open '".$batchFile."-".$ARGV[0]."'");
	print FBATCH "BEGIN TRANSACTION;";
	for my $pkgDel (@pkgsDel) {
		if ($pkgDel !~ /^\.\// || $pkgDel !~ /\.(tgz|txz)$/) {
			next;
		} # if $pkgDel
		$pkgDel = substr($pkgDel, 2);
		my @arrPath = split(/\//, $pkgDel);
	
		my $pkgName = pop(@arrPath);
		my $idPkg = $slib->getPkgId($pkgName);

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
		my $serSQL;
		if ($idSerie eq 'NULL') {
			$serSQL = "IS NULL";
		} else {
			$serSQL = "= ".$idSerie;
		}
		my %hashPkgs = ( IDSVER => $idSlackVer,
			IDCAT => $idCategory,
			IDSER => $idSerie,
			IDPKG => $idPkg,
		);
		my $idPkgs = $slib->getPkgsId(\%hashPkgs);
		next if ($idPkgs == 0);
		print FBATCH "DELETE FROM files WHERE id_packages = $idPkgs;\n";
		my $sql100 = sprintf("DELETE FROM packages WHERE id_package = %i AND 
			id_slackversion = %i AND id_category = %i AND id_serie %s;",
			$idPkg, $idSlackVer, $idCategory, $serSQL);
		$dbh->do($sql100);
	}
	print FBATCH "COMMIT;";
	close(FBATCH);
}

### PKGS ###
open(FPKGS, "./FILELIST.TXT.pkgs")
	or die("Unable to open FILELIST.TXT.pkgs");

printf("Processing packages...\n");
my $categoryLast = '';
my $idSerieLast = 0;
my $idCatLast = 0;
my $serieLast = '';
my $idSerie;
while (my $linePkg = <FPKGS>) {
	chomp($linePkg);
	my @arrLine = split(' ', $linePkg);
# FORMAT ~ 4 - size; 5 - date; 6 - time; 7 pkgname
	unless ($arrLine[7]) {
		next;
	} # unless $arrLine[7]
	if ($arrLine[7] !~ /^\.\// || $arrLine[7] !~ /\.(tgz|txz)$/) {
		next;
	} # if $arrLine[7]
	next unless (exists($pkgsAdd{$arrLine[7]}) 
		|| exists($pkgsMod{$arrLine[7]}));

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
	my $sql101;
	# HOTFIX !!!
	my $sql102 = sprintf("SELECT id_packages FROM packages WHERE
	id_slackversion = %i AND id_category = %i AND id_serie = %s AND
	id_package = %i;", $idSlackVer, $idCategory, $idSerie, $idPkg);
	my $result102 = $dbh->selectrow_array($sql102);
	if (exists($pkgsAdd{"./".$arrLine[7]}) && !$result102) {
		$sql101 = sprintf("INSERT INTO packages (id_slackversion, id_category, 
		id_serie, id_package, package_size, package_created) 
		VALUES (%i, %i, %s, %i, %i, '%s %s');", $idSlackVer, $idCategory, 
		$idSerie, $idPkg, $arrLine[4], $arrLine[5], $arrLine[6]);
	} else {
		my $serSQL;
		if ($idSerie eq 'NULL') {
			$serSQL = "IS NULL";
		} else {
			$serSQL = "= ".$idSerie;
		}
		$sql101 = sprintf("UPDATE packages SET package_size = %i, 
			package_created = '%s %s' WHERE id_slackversion = %i AND 
			id_category = %i AND id_serie %s;", $arrLine[4], $arrLine[5], 
			$arrLine[6], $idSlackVer, $idCategory, $serSQL);
	}
	$dbh->do($sql101) or die("Unable to insert package.");
} # while my $linePkg

close(FPKGS);

### PKGS MD5 ###
open(FPKGS5, "./CHECKSUMS.md5.pkgs")
	or die("Unable to open CHECKSUMS.md5.pkgs");
printf("Processing package's MD5s...\n");
# ToDo - small problem here is what IF new manifest gets added
while (my $linePkg5 = <FPKGS5>) {
	chomp($linePkg5);
	my @arrLine = split(' ', $linePkg5);
	if ($arrLine[1] !~ /^\.\// || $arrLine[1] !~ /\.(tgz|txz)$/) {
		next;
	} # unless $arrLine
	$arrLine[1] = substr($arrLine[1], 2);
	my @arrPath = split('/', $arrLine[1]);

	next unless (exists($pkgsAdd{$arrLine[1]}) 
		&& exists($pkgsMod{$arrLine[1]}));

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
### MANIFEST.bz2 ###
if ( -e "./FILELIST.TXT.files.manifests" ) {
	open(FMANS, "./FILELIST.TXT.files.manifests") 
		or die("Unable to open FILELIST.TXT.files.manifests");
	printf("Processing manifests. This is going to be a while.\n");
	$slib->_set_pkgsAdd(\%pkgsAdd) if (%pkgsAdd);
	$slib->_set_pkgsMod(\%pkgsMod) if (%pkgsMod);
	while (my $lineMan = <FMANS>) {
		chomp($lineMan);
		my @arrLine = split(' ', $lineMan);
		unless ($arrLine[7]) {
			next;
		}
		unless ($arrLine[7] =~ /\.bz2$/i) {
			next;
		}
		next unless (exists($fileAdd{$arrLine[7]})
			|| exists($fileMod{$arrLine[7]}));
		$slib->processManifestFile($arrLine[7], $idSlackVer, 1);
		# ToDo - small problem here is what IF new manifest gets added
		my $sql300 = sprintf("UPDATE datafile SET dfile_created = '%s %s' WHERE 
			id_slackversion = %i AND fpath = '%s';", $arrLine[5], $arrLine[6],
		$idSlackVer, $arrLine[7]);
		$dbh->do($sql300) or die("Unable to insert datafile.");
	}
	close(FMANS);
}
### PACKAGES.TXT ###
if ( -e "./FILELIST.TXT.files.desc" ) {
	open(FDESC, "./FILELIST.TXT.files.desc") 
		or die("Unable to open FILELIST.TXT.files.desc");
	printf("Processing package's descriptions...\n");
	while (my $lineDesc = <FDESC>) {
		chomp($lineDesc);
		my @arrLine = split(' ', $lineDesc);
		unless ($arrLine[7]) {
			next;
		}
		unless ($arrLine[7] =~ /\.txt$/i) {
			next;
		}
		next unless (exists($fileAdd{$arrLine[7]}) 
			|| exists($fileMod{$arrLine[7]}));
		$slib->processPkgDesc($arrLine[7], $idSlackVer);
		# ToDo - A/M and act accordingly with DIFF
		my $sql400 = sprintf("UPDATE datafile SET dfile_created = '%s %s' 
			WHERE id_slackversion = %i AND fpath = '%s';", 
			$arrLine[5], $arrLine[6], $idSlackVer, $arrLine[7]);
		$dbh->do($sql400) or die("Unable to insert datafile.");
	}
	close(FDESC);
}
### SVER DATA FILES MD5 ###
open(DFILE5, "./CHECKSUMS.md5.files")
	or die("Unable to open CHECKSUMS.md5.files");
printf("Processing datafile's MD5s ...\n");
while (my $lineDF5 = <DFILE5>) {
	chomp($lineDF5);
	my @arrLine = split(' ', $lineDF5);
	unless ($arrLine[1]) {
		next;
	}
	if ($arrLine[1] !~ /^\.\//) {
		next;
	}
	my $sql500 = sprintf("UPDATE datafile SET dfile_md5sum = '%s' WHERE 
		fpath = '%s' AND id_slackversion = %i;", $arrLine[0], $arrLine[1], 
		$idSlackVer);
	$dbh->do($sql500) or die("Unable to update datafile's MD5 sum.");
} # while my $lineDF5
close(DFILE5);

### Update update time
my $sql888 = sprintf("UPDATE slackversion SET ts_last_update = NOW() WHERE \
id_slackversion = %i;", $idSlackVer);
$dbh->do($sql888);

### Update pkgs count ;;; No. files is being updated from ex.script;
# TODO - this "needs" to be rewritten
my $sql999 = sprintf("UPDATE slackversion SET no_pkgs = (SELECT COUNT(*) \
FROM view_packages WHERE id_slackversion = %i) WHERE \
id_slackversion = %i;", $idSlackVer, $idSlackVer);
$dbh->do($sql999);

$dbh->commit;
$dbh->disconnect;

