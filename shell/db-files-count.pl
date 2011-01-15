#!/usr/bin/perl
# 2010/Mar/18 @ Zdenek Styblik
use lib "/srv/httpd/search.slackware.eu/perl/";
use Slackware::Search::ConfigParser qw(_getConfig);

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
		RaiseError => 0, 
		PrintError => 1
	}
);

die ("Unable to connect to DB.") unless ($dbh);

### MAIN ###
my $numArgs = $#ARGV + 1;

if ($numArgs == 0) {
	printf("Parameter must be Slackware version.\n");
	exit 1;
}

if ($ARGV[0] !~ /^slackware(64)?-([0-9]+\.[0-9]+|current){1}$/i) {
	printf("Parameter '%s' doesn't look like Slackware version to me.\n", 
		$ARGV[0]);
	exit 1;
}

my $sqLiteFile = sprintf("%s/%s.sq3", $CFG{SQLITE_PATH}, $ARGV[0]);
my $dbhLite = DBI->connect("dbi:SQLite:dbname=".$sqLiteFile, 
	"","", 
	{ AutoCommit => 1,
    PrintError => 0,
		RaiseError => 0
	}
);

die ("Unable to open SQLite file '$sqLiteFile'") unless ($dbhLite);

my $sql1 = "SELECT COUNT(*) FROM files;";
my $filesCount = $dbhLite->selectrow_array($sql1) 
	or die("Unable to select files count.");
$dbhLite->disconnect;

my $sql2 = sprintf("UPDATE slackversion SET no_files = %i WHERE \
slackversion_name = '%s';", $filesCount, $ARGV[0]);
$dbh->do($sql2) or die("Unable to update files count.");
$dbh->commit;
$dbh->disconnect;

exit 0;

