#!/usr/bin/perl
# 2010/Mar/16 @ Zdenek Styblik
# desc: Fix Slackware's package's descriptions
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
### PACKAGES.TXT ###
my $filesTxt = "./FILELIST.TXT.files.desc";
if ( -e $filesTxt ) {
	open(FDESC, $filesTxt) or die("Unable to open FILELIST.TXT.files.desc");
	print "Processing package's descriptions...\n";
	while (my $lineDesc = <FDESC>) {
		chomp($lineDesc);
		my @arrLine = split(' ', $lineDesc);
		unless ($arrLine[7]) {
			next;
		}
		unless ($arrLine[7] =~ /\.txt$/i) {
			next;
		}
		printf("* %s\n", $arrLine[7]);
		$slib->processPkgDesc($arrLine[7], $idSlackVer);
	}
	close(FDESC);
}

$dbh->commit;
$dbh->disconnect;

