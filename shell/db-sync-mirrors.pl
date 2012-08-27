#!/usr/bin/perl
# 2010/Mar/15 @ Zdenek Styblik
#
# Desc: sync 'us' -> 'United States' aliases, resp. mirror locations
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

my $slacksite = 'http://mirrors.slackware.com/mirrorlist/';
my $debug = $ENV{'DEBUG'} || 0;

my $cfgParser = 'Slackware::Search::ConfigParser';
my %CFG = $cfgParser->_getConfig(CFGFILE);

unless (%CFG || keys(%CFG)) {
	printf("Parsing of config file has failed.\n");
	exit 2;
}

### MAIN ###
my $browser = LWP::UserAgent->new;
my $response = $browser->get($slacksite) 
	or die("Unable to get URL '$slacksite'.");
die ("Error while getting URL '$slacksite'.") if ($response->is_error());

my %countries;
for my $line1 ( split(/\n/, $response->content) ) {
	chomp($line1);
	if ($line1 !~ /<a href=/) {
		next;
	}

	$line1 =~ />.*\(([A-Za-z]{2}+)\).*</;
	if (!$1) {
		next;
	}
	$countries{$1} = 1;
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

# Synchronize aliases 'us' -> 'United States'
for my $country (keys(%countries)) {
	my $sql100 = sprintf("SELECT id_country FROM country WHERE flag_url LIKE '%%/%s.png' LIMIT 1;",
		$country);
	printf STDERR "``%s''\n", $sql100 if ($debug > 0);
	my $id_country = $dbh->selectrow_array($sql100);
	if (!$id_country || $id_country !~ /^[0-9]+$/) {
		$id_country = 'NIL';
		printf STDERR "Country '%s' not found in DB.\n", $country;
		next;
	}
	printf STDERR "country:id_country:%s:%s\n", $country, $id_country if ($debug > 0);
	my $sql120 = sprintf("UPDATE country SET name_short = '%s' WHERE id_country = %s;",
		$country, $id_country);
	printf STDERR "``%s''\n", $sql120 if($debug > 0);
	$dbh->do($sql120) or die("Unable to execute '".$sql120."'");
} # for my $country

# Insert mirrors and link them with countries
for my $line ( split(/\n/, $response->content) ) {
	chomp($line);
	if ($line !~ /<a href=/) {
		next;
	}
	$line =~ />.*\(([A-Za-z]{2}+)\).*</;
	my $mirror_country = $1 || 'NIL';
	if (length($mirror_country) != 2) {
		printf STDERR "Invalid line: ``%s''\n", $line;
		next;
	}
	my $sql150  = sprintf("SELECT id_country FROM country WHERE name_short = '%s';",
		$mirror_country);
	my $id_country = $dbh->selectrow_array($sql150);
	if (!$id_country || $id_country !~ /^[0-9]+$/) {
		printf STDERR "Country '%s' not found in DB.\n", $mirror_country;
		printf STDERR "Input line was: ``%s''\n", $line;
		next;
	}

	my $pos_end = index($line, '</a>');
	my $pos_begin = rindex($line, '>', $pos_end);
	my $mirror_url = substr($line, $pos_begin+1, $pos_end - $pos_begin - 1);
	if ($mirror_url !~ /^(http|ftp|rsync):\/\/.+$/) {
		printf STDERR "Invalid mirror URL: '%s'.\n", $mirror_url;
		printf STDERR "Input line was: ``%s''\n", $line;
		next;
	}

	my $sql160 = sprintf("SELECT COUNT(id_mirror) FROM mirror WHERE mirror_url = '%s' AND id_country = %s;",
		$mirror_url, $id_country);
	my $mirror_count = $dbh->selectrow_array($sql160);
	my $sql170 = "";
	if ($mirror_count == 1) {
		$sql170 = sprintf("UPDATE mirror SET mirror_updated = now() WHERE mirror_url = '%s' AND id_country = %s;",
			$mirror_url, $id_country);
	} else {
		# [0] -> proto, [1] -> desc to extract
		my @arr_url = split(/:\/\//, $mirror_url);
		my $mirror_desc = substr($arr_url[1], 0, index($arr_url[1], '/'));
		$sql170 = sprintf("INSERT INTO mirror (mirror_url, id_country, mirror_desc, mirror_proto) VALUES ('%s', %s, '%s', '%s');",
			$mirror_url, $id_country, $mirror_desc, $arr_url[0]);
	}
	printf STDERR "``%s''\n", $sql170 if ($debug > 0);
	$dbh->do($sql170) or die("Unable to execute: ``".$sql170."''");
} # for my $line

#### Clean-up DB ####
my $sql2 = "DELETE FROM mirror WHERE \
mirror_updated <= (NOW() - INTERVAL '7 DAYS');";
$dbh->do($sql2) or die("Unable to clean up in mirrors table.");

$dbh->commit;
$dbh->disconnect;
# EOF
