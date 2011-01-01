#!/usr/bin/perl
# 2010/Mar/19 @ Zdenek Styblik
use lib "/srv/httpd/search.slackware.eu/perl/";
use Slackware::Search::ConfigParser qw(_getConfig);

use DBI;
use strict;
use warnings;

use constant CFGFILE => '/srv/httpd/search.slackware.eu/conf/config.pl';

my $numArgs = $#ARGV + 1;

if ($numArgs != 1) {
	printf("Parameter must be a Slackware version.\n");
	exit 1;
}

my $slackver = $ARGV[0];

unless ($slackver !~ /^slackware(64)?-([0-9]+\.[0-9]+|current){1}$/i) {
	printf("Slackware version is garbage. Get lost!");
	exit 1;
}

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
		AutoCommit => 1, 
		RaiseError => 1, 
		PrintError => 1
	}
);

die ("Unable to connect to DB.") unless ($dbh);

my $sql1 = sprintf("SELECT id_slackversion FROM slackversion WHERE 
	slackversion_name = '%s';", $slackver);
my $result1 = $dbh->selectrow_array($sql1);
unless ($result1) {
	exit 0;
}

$dbh->disconnect;

exit 1;
