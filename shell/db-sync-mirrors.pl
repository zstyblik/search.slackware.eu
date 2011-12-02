#!/usr/bin/perl
# 2010/Mar/15 @ Zdenek Styblik
#
# Desc: get Slackware mirrors and insert them into DB
# Desc: wipe out old (removed) mirrors
#
# Copyright (c) 2011 Zdenek Styblik <zdenek.styblik@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
use lib "/mnt/search.slackware.eu/perl/";
use Slackware::Search::ConfigParser qw(_getConfig);

use strict;
use warnings;
use DBI;
use LWP;

use constant CFGFILE => '/mnt/search.slackware.eu/conf/config.pl';

my $slacksite = 'http://www.slackware.com/getslack/';
my $startMatch = '<TD><B>max. users</B></TD>';
my $stopMatch = '</TABLE>';
my $lineMatch = 'A HREF=\"(ftp|http):\/\/';

my $cfgParser = 'Slackware::Search::ConfigParser';
my %CFG = $cfgParser->_getConfig(CFGFILE);

unless (%CFG || keys(%CFG)) {
	printf("Parsing of config file has failed.\n");
	exit 2;
}

my $dbh = DBI->connect(
	$CFG{DB_DSN},
	$CFG{DB_USER},
	$CFG{DB_PASS},
	{
		AutoCommit => 0, 
		RaiseError => 1, 
		PrintError => 1
	}
);

die("Unable to connect to DB.") unless ($dbh);

### MAIN ###
my $browser = LWP::UserAgent->new;
my $response = $browser->get($slacksite) 
	or die("Unable to get URL '$slacksite'.");
die ("Error while getting URL '$slacksite'.") if ($response->is_error());

for my $line1 ( split(/\n/, $response->content) ) {
	chomp($line1);
	if ($line1 !~ /list\.php\?country=/) {
		next;
	}
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
	my $sql100 = sprintf("SELECT id_country FROM country WHERE 
	name = '%s';", $country);
	my $idCountry = $dbh->selectrow_array($sql100);
	# evaluate
	if (!$idCountry) {
		my $sql101 = sprintf("INSERT INTO country (name) VALUES ('%s');", 
			$country);
		$dbh->do($sql101);
		$idCountry = $dbh->selectrow_array($sql100);
	}
	my $response2 = $browser->get($link);
	if ($response2->is_error()) {
		printf(STDERR "Unable to get response for '%s'.\n", $link);
		next;
	}
	for my $line2 ( split(/\n/, $response2->content) ) {
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
			my $sql1 = sprintf("INSERT INTO mirror (mirror_url, id_country, \
			mirror_desc, mirror_proto) VALUES ('%s', %i, '%s', '%s');",
			$arr2[1], $idCountry, $desc, $arr3[0]);
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

