#!/usr/bin/perl
# 2010/Mar/15 @ Zdenek Styblik
#
# Desc: get Slackware mirrors and insert them into DB
# Desc: wipe out old (removed) mirrors
#
# TODO - and where is strict, hm?
use strict;
use warnings;
use DBI;

require '/srv/httpd/search.slackware.eu/conf/config.pl';

my $slacksite = 'http://www.slackware.com/getslack/';
my $startMatch = '<TD><B>max. users</B></TD>';
my $stopMatch = '</TABLE>';
my $lineMatch = 'A HREF=\"(ftp|http):\/\/';

my $dbh = DBI->connect($CFG{DB_DSN},
$CFG{DB_USER},
$CFG{DB_PASS},
	{
		AutoCommit => 0, 
		RaiseError => 1, 
		PrintError => 1
	}
);

### MAIN ###
$ENV{PATH} = '/usr/bin/';
for my $line1 (`curl -s '$slacksite'| grep 'list\.php\?country='`) 
{
	chomp($line1);
	my @arr1 = split(/"/, $line1);
	my $link = $slacksite.$arr1[1];
	my $record = 0;
	my $countryOrg = substr($arr1[2], 1, index($arr1[2], '<')-1);
	my $country;
	my @countryArr = split(//, $countryOrg);
	while (my $char = shift(@countryArr)) {
		next if ($char !~ /[A-Za-z0-9\ ]+/);
		$country.= $char;
	}
	for my $line2 (`curl -s '$link'`) {
		chomp($line2);
		if ($line2 =~ /$startMatch/i) {
			$record = 1;
			next;
		}
		if ($record == 0) {
			next;
		}
		if ($line2 =~ /$stopMatch/i) {
			$record = 0;
			last;
		}
		if ($record == 1 && $line2 =~ /$lineMatch/i) {
			my @arr2 = split(/"/, $line2);
			my @arr3 = split(/:\/\//, $arr2[1]);
			my $desc = substr($arr3[1], 0, index($arr3[1], '/'));
			my $sql1 = "INSERT INTO mirror (mirror_url, mirror_location, \
			mirror_desc, mirror_proto) VALUES ('".$arr2[1]
			."', '$country', '$desc', '".$arr3[0]."');";
#			printf("%s\n", $sql1);
			$dbh->do($sql1) or die("Unable to insert mirror");
		}
		next;
	}
}

#### Clean-up DB ####
my $sql2 = "DELETE FROM mirror WHERE \
mirror_updated <= (NOW() - INTERVAL '7 DAYS');";
$dbh->do($sql2) or die("Unable to clean up in mirrors table.");

$dbh->commit;
$dbh->disconnect;

