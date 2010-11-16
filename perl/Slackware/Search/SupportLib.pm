package Slackware::Search::SupportLib;
require Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use strict;
use warnings;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(_set_pkgsAdd _set_pkgsDel _set_pkgsMod existsSlackVer
insertSlackVer slackVerAdd getSlackVerId insertCategory getCategoryId
insertSerie getSerieId insertPkg getPkgId getPkgId updatePkgNfo 
processPkgDesc processManifestFile getPkgsId _set_dbHandler 
_set_sverName _get_batchFile);
%EXPORT_TAGS = (T1 => [qw(_set_pkgsAdd _set_pkgsDel _set_pkgsMod 
existsSlackVer insertSlackVer slackVerAdd getSlackVerId 
insertCategory getCategoryId insertSerie getSerieId insertPkg 
getPkgId getPkgId updatePkgNfo 
processPkgDesc processManifestFile getPkgsId _set_dbHandler 
_set_sverName _get_batchFile)]);


### 'globals'
my $batchFile = "/tmp/search.slack/SQLBATCH";
my $dbh;
my %pkgsAdd = ();
my %pkgsDel = ();
my %pkgsMod = ();
my $sverName = ();

sub _get_batchFile {
	return $batchFile;
} # _get_batchFile

sub _set_dbHandler {
	my $self = shift;
	$dbh = shift;
	return 0;
} # _set_dbHandler

sub _set_pkgsAdd {
	my $self = shift;
	my $tmpAdd = shift;
	%pkgsAdd = %{ $tmpAdd } if ($tmpAdd);
	return 0;
} # sub _set_pkgsAdd

sub _set_pkgsDel {
	my $self = shift;
	my $tmpDel = shift;
	%pkgsDel = %{ $tmpDel } if ($tmpDel);
	return 0;
} # sub _set_pkgsDel

sub _set_pkgsMod {
	my $self = shift;
	my $tmpMod = shift;
	%pkgsMod = %{ $tmpMod } if ($tmpMod);
	return 0;
} # sub _set_pkgsMod

sub _set_sverName {
	my $self = shift;
	# ToDo - total trust in passed name
	$sverName = shift;
	return 0;
} # _set_sverName

# desc: check whether version is already in DB
# $slackVer: string;
# @return: bool;
sub existsSlackVer {
	my $self = shift;
	my $slackVer = shift;
	my $sql1 = "SELECT COUNT(*) FROM slackversion WHERE 
	slackversion_name = '$slackVer';";
	if ($dbh->selectrow_array($sql1) == 0) {
		return 0;
	} else {
		return 1;
	}
} # sub slackVerExists
# desc: insert slackver into db
# $slackVer: string;
# @return: int;
sub insertSlackVer {
	my $self = shift;
	my $slackVer = shift;
	my ($sname, $version) = split('-', $slackVer);
	if ($version eq 'current') {
		$version = 9999;
	}
	my $sql1 = "INSERT INTO slackversion (slackversion_name, version) 
	VALUES ('$slackVer', $version);";
	$dbh->do($sql1)
		or die("Unable to insert new Slackware version.");
	my $sql2 = "SELECT id_slackversion FROM slackversion WHERE 
	slackversion_name = '$slackVer';";
	my $idSlackVer = $dbh->selectrow_array($sql2)
		or die("Unable to select Slackware version ID.");
	return $idSlackVer;
} # sub slackVerAdd
# desc: get id_slackversion from db
# $slackVer: string;
# @return: int;
sub getSlackVerId {
	my $self = shift;
	my $slackVer = shift;
	my $sql1 = "SELECT id_slackversion FROM slackversion WHERE 
	slackversion_name = '$slackVer';";
	my $idSlackVer = -1;
 	$idSlackVer = $dbh->selectrow_array($sql1);
	unless ($idSlackVer) {
		return -1;
	}
	return $idSlackVer;
} # sub getSlackVerId
# desc: insert category into db
# $category: string;
# @return: int;
sub insertCategory {
	my $self = shift;
	my $category = shift;
	my $sql1 = "INSERT INTO category (category_name) 
	VALUES ('$category');";
	$dbh->do($sql1);
	my $sql2 = "SELECT id_category FROM category WHERE 
	category_name = '$category';";
	my $idCategory = $dbh->selectrow_array($sql2) 
		or die("Unable to select category ID.");
	return $idCategory;
} # sub insertCategory
# desc: get id_category from db
# $category: string;
# @return: int;
sub getCategoryId {
	my $self = shift;
	my $category = shift; 
	my $sql1 = "SELECT id_category FROM category WHERE 
	category_name = '".$category."';";
	my $idCategory = -1; 
	$idCategory = $dbh->selectrow_array($sql1);
	unless ($idCategory) {
		return -1;
	}
	return $idCategory;
} # sub getCategoryId
# desc: insert serie into db
# $serie: string;
# @return: int;
sub insertSerie {
	my $self = shift;
	my $serie = shift;
	my $sql1 = "INSERT INTO serie (serie_name) VALUES ('$serie');";
	$dbh->do($sql1);
	my $sql2 = "SELECT id_serie FROM serie WHERE 
	serie_name = '$serie';";
	my $idSerie = $dbh->selectrow_array($sql2)
		or die("Unable to select serie ID.");
	return $idSerie;
} # sub insertSerie
# desc: get id_serie from db
# $serie: string;
# @return: int;
sub getSerieId {
	my $self = shift;
	my $serie = shift;
	my $sql1 = "SELECT id_serie FROM serie WHERE 
	serie_name = '$serie';";
	my $idSerie = -1;
 	$idSerie = $dbh->selectrow_array($sql1);
	unless ($idSerie) {
		return -1;
	}
	return $idSerie;
} # sub getSerieId
# desc: insert pkg into db
# $pkgName: string;
# @return: int;
sub insertPkg {
	my $self = shift;
	my $pkgName = shift;
	my $sql1 = "INSERT INTO package (package_name) 
	VALUES ('$pkgName');";
	$dbh->do($sql1);
	my $sql2 = "SELECT id_package FROM package WHERE 
	package_name = '$pkgName';";
	my $idPackage = $dbh->selectrow_array($sql2)
		or die("Unable to select package ID.");
	return $idPackage;
} # sub insertPkg
# desc: get id_package
# $pkgName: string;
# @return: int;
sub getPkgId {
	my $self = shift;
	my $pkgName = shift;
	my $sql1 = "SELECT id_package FROM package WHERE 
	package_name = '$pkgName';";
	my $idPkg = -1;
	$idPkg = $dbh->selectrow_array($sql1);
	unless ($idPkg) {
		return -1;
	}
	return $idPkg;
} # sub getPkgId
# desc: update description of package
# $hashNfo: hash reference;
# @return: bool;
sub updatePkgNfo {
	my $self = shift;
	my $hashNfo = shift;
	my @reqKeys = qw(PKGNFO IDPKG IDSER IDCAT IDSVER);
	for my $reqKey (@reqKeys) {
		unless (exists($hashNfo->{$reqKey})) {
			return -1;
		}
	} # for my $reqKey
	$hashNfo->{PKGNFO} =~ s/[']+/"/g;
	my $sql1 = "UPDATE packages SET package_desc = (E'"
	.$hashNfo->{PKGNFO}."') WHERE id_package = ".$hashNfo->{IDPKG}
	." AND id_serie = ".$hashNfo->{IDSER}." AND id_category = "
	.$hashNfo->{IDCAT}." AND id_slackversion = "
	.$hashNfo->{IDSVER}.";";
	$dbh->do($sql1) or die("Unable to update package's desc.");
	return 0;
}
# desc: update package's description
# $fpath: string;
# $idSlackVer: int;
# @return: bool;
sub processPkgDesc {
	my $self = shift;
	my $fpath = shift;
	my $idSlackVer = shift;
	unless ( -e $fpath ) {
		return -1;
	} # unless -e
	open(FDESC, $fpath) or die("Unable to open $fpath");
	$fpath = substr($fpath, 2);
	my $idCategory;
	my $category;
	my @arrFPath = split('/', $fpath);
	$category = shift @arrFPath;
	$idCategory = $self->getCategoryId($category);
	if ($idCategory == -1) {
		return -1;
	} # if $idCategory
	my $idPkg = undef;
	my $idSerie = undef;
	my $pkgInfo = '';
	my $pkgName = '';
	while (my $lineDesc = <FDESC>) {
		if ($lineDesc =~ /^[\W]+$/) {
			next;
		} # if EMPTY_LINE
		if ($lineDesc =~ /^PACKAGE NAME:/) {
			if ($idPkg && $idSerie) {
				my %item = ( PKGNFO => $pkgInfo,
					IDPKG => $idPkg,
					IDSER => $idSerie,
					IDCAT => $idCategory,
					IDSVER => $idSlackVer,
				);
				$self->updatePkgNfo(\%item);
				$idPkg = undef;
				$idSerie = undef;
			} # if $idPkg && $idSerie
			my @arr = split(' ', $lineDesc);
			$pkgName = substr($arr[2], rindex($arr[2], '/') + 1, 
				length $arr[2]);
			$pkgInfo = undef;
			$idPkg = $self->getPkgId($pkgName);
			if ($idPkg == -1) {
				$idPkg = undef;
				$idSerie = undef;
				$pkgInfo = undef;
			} # if $idPkg
			next;
		} # if PACKAGE NAME
		if ($lineDesc =~ /^PACKAGE LOCATION:/) {
			my @arr = split(' ', $lineDesc);
			unless ($arr[2]) {
				$idPkg = undef;
				$idSerie = undef;
				$pkgInfo = undef;
				next;
			} # unless $arr[2]
			if ($arr[2] !~ /^\.\//) {
				$idPkg = undef;
				$idSerie = undef;
				$pkgInfo = undef;
				next;
			} # unless $arr[1]
			$arr[2] = substr($arr[2], 2);
			my @arr2 = split('/', $arr[2]);
			unless ($arr2[0] eq $category) {
				$idPkg = undef;
				$idSerie = undef;
				$pkgInfo = undef;
				next;
			} # unless $arr2[0] eq
			shift(@arr2);
			my $serie = '';
			for my $entry (@arr2) {
				$serie.= $entry;
			} # for my $entry
			unless ($serie) {
				$idSerie = 'NULL';
			} else {
				$idSerie = $self->getSerieId($serie);
				if ($idSerie == -1) {
					$idSerie = 'NULL';
				} # if $idCategory -1
			} # if @arr2 == 1
			next;
		} # if PACKAGE LOCATION
		if (($idPkg) && ($idSerie)) {
				$pkgInfo.= $lineDesc;
		} # if $idPackage && $idSeries
		# anything else is considered as garbage
	} # while my $lineDesc
	if ($idPkg && $idSerie) {
		my %item = ( PKGNFO => $pkgInfo,
			IDPKG => $idPkg,
			IDSER => $idSerie,
			IDCAT => $idCategory,
			IDSVER => $idSlackVer,
		);
		$self->updatePkgNfo(\%item);
	} # if $idPkg && $idSerie
	return 0;
}
# desc: process MANIFEST file
# $fpath: string;
# @return: bool;
sub processManifestFile {
	my $self = shift;
	my $fpath = shift;
	my $idSlackVer = shift;
	my $update = shift || 0;
	unless ( -e $fpath && $fpath =~ /\.bz2$/) {
		return -1;
	} # unless -e $fpath
	my $outFile = $fpath;
	$outFile =~ s/\.bz2$//g;
	`bzip2 -d -k -c $fpath > $outFile`;
	unless ( -e $outFile ) {
		return -1;
	} # unless -e $outFile
	$fpath = substr($fpath, 2);
	my @arrFPath = split('/', $fpath);
	my $idCategory = $self->getCategoryId($arrFPath[0]);
	my $category = $arrFPath[0];
	if ($idCategory == -1) {
		return -1;
	}
	open(FMAN, $outFile) or die("Unable to open $outFile");
	my $seriePrev = '';
	my $idSeriePrev = undef;
	my $idPkgs = undef;
	my $fPathPrev = '';
	my $idFPathPrev = undef;
	my $toBatchFile = $batchFile."-".$sverName;
	if ( -e $toBatchFile ) {
		open(FBATCH, '>>'.$toBatchFile);
	} else {
		open(FBATCH, '>>'.$toBatchFile);
		print FBATCH "CREATE TABLE files (id_files INTEGER PRIMARY KEY, "
		."id_packages INTEGER, "
		."file_name TEXT, file_size INTEGER, file_created TEXT, "
		."file_acl TEXT, file_owner TEXT);\n" if ($update == 0);
	}
	print FBATCH "BEGIN TRANSACTION;";
	my $lineCount = 0;
#	my $contents = '';
	my ($package, $pkgName);
	while (my $lineMan = <FMAN>) {
		chomp($lineMan);
		if ($lineMan =~ /^[\W]+$/) {
			next;
		} # if EMPTY_LINE
		$lineCount++;
		if (($lineCount%40000) == 0) {
			print FBATCH "COMMIT;";
			print FBATCH "BEGIN TRANSACTION;";
		}
		if ( ($lineMan =~ /^[|]{2}/s) && ($lineMan =~ /Package:/s) ) {
			$package = substr ($lineMan, rindex ($lineMan, ' ') + 1);
#			if ($idPkgs) {
#				my $sqlT = "UPDATE packages SET package_contents = 
#				'".$contents."' WHERE 
#				id_packages = $idPkgs AND id_slackversion = $idSlackVer AND 
#				id_category = $idCategory;";
#				$dbh->do($sqlT) or die("Oh, crap!");
#				$contents = '';
#			}
			if ($package !~ /^\.\//) {
				print "I've probably miscaught package! :(\n [$package]\n";
				$idPkgs = undef;
				next;
			}
			$package =~ s/^\.\///g;
			if ($update == 1) {
				my $pkgKey = "./".$category."/".$package;
				unless (exists($pkgsAdd{$pkgKey}) 
					|| exists($pkgsMod{$pkgKey})) 
				{
					$idPkgs = undef;
					next;
				}
			}
			my @arr = split('/', $package);
			$pkgName = pop(@arr);
			unless ($pkgName =~ /\.(tgz|txz)$/) {
				$idPkgs = undef;
				next;
			}
			
			my $idSerie = -1;
			my $serie = join("/", @arr);
			unless ($serie) {
				$idSerie = 'NULL';
			} else {
				if ($serie eq $seriePrev) {
					$idSerie = $idSeriePrev;
				} else {
					$idSerie = $self->getSerieId($serie);
					if ($idSerie == -1) {
						$idSerie = 'NULL';
					} else {
						$idSeriePrev = $idSerie;
						$seriePrev = $serie;
					}
				}
			} # unless $serie

			my $idPkg = $self->getPkgId($pkgName);
			my %hashPkgs = (IDSVER => $idSlackVer, 
				IDCAT => $idCategory, 
				IDSER => $idSerie, 
				IDPKG => $idPkg
			);
			$idPkgs = $self->getPkgsId(\%hashPkgs);
			if ($idPkgs == -1) {
				print "[man]".$category."::".$serie."::".$pkgName."\n";
				$idPkgs = undef;
				next;
			}
			if ($update == 1) {
				my $pkgKey = "./".$category."/".$package;
				if (exists($pkgsMod{$pkgKey})) {
					print FBATCH "DELETE FROM files WHERE "
					."id_packages = $idPkgs;";
				}
			}
			next;
		} # if $lineMan =~ /^\b||...
		if ($lineMan =~ /^[a-z\-]{1}+/s) {
			unless ($idPkgs) {
				next;
			}
			#	acl	owner	size	date	time	fullpath
			#	0		1			2			3			4			5
			my @arr = split(' ' , $lineMan);
			if ($arr[5] eq './') {
				next;
			}
			if ($arr[2] =~ /,/) {
				$arr[2] = 0;
			}
#			$contents.= $arr[5];
			print FBATCH "INSERT INTO files (id_packages, "
			."file_name, file_size, file_created, file_acl, "
			."file_owner) VALUES ($idPkgs, '".$arr[5]."', '".$arr[2]."', '"
			.$arr[3]." ".$arr[4]."', '".$arr[0]."', '".$arr[1]."');\n";
		} # if ($line =~ /^[a-z\-]{1}+/s)
	} # while my $lineMan
#	if ($idPkgs) {
#		my $sqlT = "UPDATE packages SET package_contents = 
#		'".$contents."' WHERE 
#		id_packages = $idPkgs AND id_slackversion = $idSlackVer AND 
#		id_category = $idCategory;";
#		$dbh->do($sqlT) or die("Oh, crap!");
#	}
	close(FMAN);
	print FBATCH "COMMIT;";
	close(FBATCH);
	`rm $outFile;`;
	return 0;
}
# desc: get id_packages from packages table
# $hashPkgs: hash reference;
# @return: int;
sub getPkgsId {
	my $self = shift;
	my $hashPkgs = shift;
	my @reqKeys = qw(IDSVER IDCAT IDSER IDPKG);
	for my $reqKey (@reqKeys) {
		unless (exists($hashPkgs->{$reqKey})) {
			return -1;
		}
	}
	my $sqlSer = "IS ";
	if ($hashPkgs->{IDSER} =~ /[0-9]+/) {
		$sqlSer = "= ";
	}
	my $sql1 = "SELECT id_packages FROM packages WHERE 
	id_slackversion = ".$hashPkgs->{IDSVER}." AND id_category = "
	.$hashPkgs->{IDCAT}." AND id_serie ".$sqlSer.$hashPkgs->{IDSER}
	." AND id_package = ".$hashPkgs->{IDPKG}.";";
	my $idPkgs = -1;
 	$idPkgs = $dbh->selectrow_array($sql1);
	unless ($idPkgs) {
		return -1;
	}
	return $idPkgs;
} # getPkgsId

1;
