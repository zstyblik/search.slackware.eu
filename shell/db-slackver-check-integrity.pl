#!/usr/bin/perl
# 2011/Jan/17 @ Zdenek Styblik
# Desc: check DB integrity of given Slackware version
use lib "/srv/httpd/search.slackware.eu/perl/";
use Slackware::Search::ConfigParser qw(_getConfig);
use Slackware::Search::SupportLib;

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

if ($numArgs < 2) {
	printf("Parameter #1 must be: <Slackware version>\n");
	printf("Parameter #2 must be: <desc|md5|files>\n");
	exit 1;
}

if ($ARGV[0] !~ /^slackware(64)?-([0-9]+\.[0-9]+|current){1}$/i) {
	printf("Parameter '%s' doesn't look like Slackware version to me.\n",
		$ARGV[0]);
	exit 1;
}

my $slackVer = $ARGV[0];
my $action = $ARGV[1];

my $slib = 'Slackware::Search::SupportLib';
$slib->_set_dbHandler($dbh);

my $sverExists = $slib->existsSlackVer($slackVer);
if ($sverExists == 0) {
	printf("This Slackware version is not in DB.\n");
	printf("Please use add script.\n");
	exit 1;
}
my $idSlackVer = 0;
$idSlackVer = $slib->getSlackVerId($slackVer);
$slib->_set_sverName($ARGV[0]);

my ($category, $garbage) = split(/-/, $slackVer);

if ($action -eq 'desc') {
	# Check for PKGS w/o MD5 sums
	my $sql099 = sprintf("SELECT id_category FROM category WHERE 
		category_name = '%s';", $category);
	my $idCategory = $dbh->selectrow_array($sql099);
	unless ($idCategory) {
		print STDERR "I can't find category '$category' in database!!!";
		exit 0;
	}
	my $sql100 = sprintf("SELECT id_packages, package_name FROM view_packages 
		WHERE (id_slackversion = %i AND id_category = %i) AND package_desc 
		IS NULL;", $idSlackVer, $idCategory);

	my $result100 = $dbh->selectall_arrayref($sql100, { Splice => {} }) 
		or die("Unable to SQL100.");
	$dbh->disconnect;
	if ($result100) {
		exit 1;
	}
} # $action -eq desc 
elsif ($action -eq 'md5') {
	# Check for PKGS w/o MD5 sums
	my $sql099 = sprintf("SELECT id_category FROM category WHERE 
		category_name = '%s';", $category);
	my $idCategory = $dbh->selectrow_array($sql099);
	unless ($idCategory) {
		print STDERR "I can't find category '$category' in database!!!";
		exit 0;
	}
	my $sql100 = sprintf("SELECT id_packages, package_name FROM view_packages 
		WHERE (id_slackversion = %i AND id_category = %i) AND package_md5sum IS 
		NULL;", $idSlackVer, $idCategory);

	my $result100 = $dbh->selectall_arrayref($sql100, { Splice => {} }) 
		or die("Unable to SQL100.");

	$dbh->disconnect;
	if ($result100) {
		exit 1;
	}
} # $action -eq md5 
elsif ($action -eq 'files') {
	# Check for PKGS w/o FILES
	my $sql200 = sprintf("SELECT id_packages FROM packages WHERE 
		id_slackversion = %i;", $idSlackVer);
	my $result200 = $dbh->selectall_arrayref($sql200, { Splice => {} }) 
		or die("Unable to select packages count from PgSQL.");

	my $sqlitePath = $CFG{SQLITE_PATH};
	my $sqLiteFile = sprintf("%s/%s.sq3", $sqlitePath, $slackVer);
	unless ( -e $sqLiteFile ) {
		my $errMsg = sprintf("SQLite file doesn't exist for '%s'.", $slackVer);
		print STDERR $errMsg;
		exit 0;
	}

	my $dbhLite = DBI->connect("dbi:SQLite:dbname=".$sqLiteFile, 
		"","", 
		{ AutoCommit => 1,
			PrintError => 0,
			RaiseError => 0
		}
	);

	unless ($dbhLite) {
		my $errMsg = sprintf("Failed to connect to SQLite '%s'.", $slackVer);
		print STDERR $errMsg;
		exit 0;
	}

	my $sql300 = "SELECT DISTINCT(id_packages) FROM files;";
	my $result300 = $dbhLite->selectall_arrayref($sql300, 
		{ Splite => {}}) or die("Unable to select packages count from SQLite.");

	$dbh->disconnect;
	$dbhLite->disconnect;

	unless ($result200 != $result300) {
		exit 1;
	}
} else {
	printf("Invalid parameter '%s'\n", $action);
	exit 0;
}

