#!/usr/bin/perl
# 2010/Dec/31 @ Zdenek Styblik
# Desc: take standard template and pre-generate HTML 
# for further processing
use strict;
use warnings;

use lib "/srv/httpd/search.slackware.eu/perl/";
use Slackware::Search::configParser qw(_getConfig);
use HTML::Template;

use const CFGFILE => '/srv/httpd/search.slackware.eu/conf/config.pl';

my $numArgs = $#ARGV + 1;

unless ($numArgs != 1) 
	|| ($ARGV[0] !~ /^slackware(64)?-([0-9]+\.[0-9]+|current){1}$/i) {
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
my $title = sprintf("Changelog %s", $sver);
$template->param(TITLE => $title);

my $outFile = sprintf(">%s/%s.htm.new", $CFG{TMPDIR}, $sver);

open(FHTML, $outFile) or die("Unable to open HTML out-file.");
print FHTML $template->output();
close(FHTML);

