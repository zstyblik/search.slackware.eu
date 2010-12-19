#!/usr/bin/perl
# 2010/Mar/19 @ Zdenek Styblik
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
		RaiseError => 1, 
		PrintError => 1
	}
);

die ("Unable to connect to DB.") unless ($dbh);

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

