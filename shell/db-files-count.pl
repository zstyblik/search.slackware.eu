#!/usr/bin/perl
# 2010/Mar/18 @ Zdenek Styblik

use DBI;
use strict;
use warnings;

my $idSlackVer = -1;
my $sqLitePath = '/home/search.slackware.eu/db/';
my $dbHost = '/home/search.slackware.eu/var/run/postgres/';
my $dbPort = 21000;
my $dbName = 'pkgs';
my $dbUser = 'pkgs';
my $dbPass = 'swarePkgs';

my $dbh = DBI->connect("DBI:Pg:dbname=$dbName;
	host=$dbHost;port=$dbPort;",
	$dbUser,
	$dbPass,
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
	print "Parameter must be Slackware version.\n";
	exit 1;
}

if ($ARGV[0] !~ /^slackware(64)?-([0-9]+\.[0-9]+|current){1}$/i) {
	print "Parameter doesn't look like Slackware version to me."
	.$ARGV[0]."\n";
	exit 1;
}

my $sqLiteFile = $sqLitePath."/".$ARGV[0].".sq3";
my $dbhLite = DBI->connect("dbi:SQLite:dbname=".$sqLiteFile, 
	"","", 
	{ AutoCommit => 1,
    PrintError => 0,
		RaiseError => 0
	}
);

die ("Unable to open SQLite file $sqLiteFile") unless ($dbhLite);

my $sql1 = "SELECT COUNT(*) FROM files;";
my $filesCount = $dbhLite->selectrow_array($sql1) 
	or die("Unable to select files count.");
$dbhLite->disconnect;

my $sql2 = "UPDATE slackversion SET no_files = $filesCount WHERE \
slackversion_name = '".$ARGV[0]."';";
$dbh->do($sql2) or die("Unable to update files count.");
$dbh->commit;
$dbh->disconnect;

exit 0;

1;
