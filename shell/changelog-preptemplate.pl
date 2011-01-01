#!/usr/bin/perl
# 2010/Dec/31 @ Zdenek Styblik
# Desc: take standard template and pre-generate HTML 
# for further processing


# replace http://... with <a href=...
# and that's about it.

use strict;
use warnings;

use lib "/srv/httpd/search.slackware.eu/perl/";
use Slackware::Search::ConfigParser qw(_getConfig);
use HTML::Template;

use constant CFGFILE => '/srv/httpd/search.slackware.eu/conf/config.pl';

my $numArgs = $#ARGV + 1;

if ($numArgs != 1
	|| $ARGV[0] !~ /^slackware(64)?-([0-9]+\.[0-9]+|current){1}$/i) {
	printf("This script takes only one argument - slackwareversion.\n");
	printf("Example: slackware64-13.1\n");
	exit 1;
}

my $cfgParser = 'Slackware::Search::ConfigParser';
my %CFG = $cfgParser->_getConfig(CFGFILE);

unless (%CFG || keys(%CFG)) {
	printf("Parsing of config file has failed.\n");
	exit 2;
}

my $sver = $ARGV[0];

my $template = HTML::Template->new(filename => 'index.htm', 
	path => [$CFG{TMPL_PATH}],
);

$template->param(CHANGELOG => 'REPLACEME');
$template->param(QSEARCHHIDE => 1);
my $title = sprintf("Changelog of %s", $sver);
$template->param(TITLE => $title);

my $fileHtmlOut = sprintf(">%s/%s.tmpl", $CFG{TMPDIR}, $sver);

open(FHTML, $fileHtmlOut) or die("Unable to open HTML out-file.");
print FHTML $template->output();
close(FHTML);

my $tagPreOpen = 0;
my $fileChlog = sprintf("%s/%s/ChangeLog.txt", $CFG{TMPDIR}, $sver);
my $fileChlogNew = sprintf(">%s/changelogs/%s/ChangeLog.tmp", $CFG{TMPDIR},
$sver);
open(FCHLOG, $fileChlog) or die("Unable to open ChangeLog.");
open(FCHLOGNEW, $fileChlogNew) 
	or die("Unable to open ChangeLog for output.");
while (my $line = <FCHLOG>) {
	chomp($line);
	if ($line =~ /^[A-Za-z]{3}[\ ]+[A-Za-z]{3}[\ ]+[0-9]{1,2}[\	]+[0-9]{2}:[0-9]{2}:[0-9]{2}[\ ]+[A-Z]{3,4}[\ ]+[0-9]{4}$/) {
		$line =~ s/(^[A-Za-z]{3}[\ ]+[A-Za-z]{3}[\ ]+[0-9]{1,2}[\ ]+[0-9]{2}:[0-9]{2}:[0-9]{2}[\ ]+[A-Z]{3,4}[\ ]+[0-9]{4}$)/<h5>\1<\/h5><pre>/;
		$tagPreOpen = 1;
		goto PRINTLINE;
	}
	if ($line =~ /^[-]+$/) {
		$line =~ s/^[-]+$/<\/pre><hr \/>/;
		$tagPreOpen = 0;
		goto PRINTLINE;
	}	
	$line =~ s/</&lt;/g;
	$line =~ s/>/&gt;/g;
	$line =~ s/&/&#38;/g;
	PRINTLINE:
	printf FCHLOGNEW $line;
	printf FCHLOGNEW "\n";
} # while my $lineChlog
if ($tagPreOpen == 1) {
	print FCHLOGNEW "</pre>\n";
}
close(FCHLOG);
close(FCHLOGNEW);

