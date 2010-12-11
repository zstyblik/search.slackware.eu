#!/usr/bin/perl
# 2010/Mar/19 @ Zdenek Styblik
use lib "/srv/httpd/search.slackware.eu/perl/";
use Slackware::Search::ConfigParser;

use DBI;
use strict;
use warnings;

my $dbHost = '/tmp/';
my $dbPort = 5432;
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

unless ($dbh) {
	print "Unable to connect to DB.";
	exit 1;
}

my $sql1 = "SELECT slackversion_name FROM slackversion;";
my $result1 = $dbh->selectall_arrayref($sql1, { Slice => {} });
unless ($result1) {
	exit 2;
}
my @versions;
for my $row (@$result1) {
	push(@versions, $row->{slackversion_name});
}
my $string = join(' ', @versions);
$dbh->disconnect;
printf("%s\n", $string);

exit 0;

