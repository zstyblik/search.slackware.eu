#!/usr/bin/perl
# 2010/Dec/31 @ Zdenek Styblik
# Desc: take standard templates and pre-generate HTML 
# for further processing
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
use strict;
use warnings;

use lib "/mnt/search.slackware.eu/perl/";
use Slackware::Search::ConfigParser qw(_getConfig);
use HTML::Template;

use constant CFGFILE => '/mnt/search.slackware.eu/conf/config.pl';

my $numArgs = $#ARGV + 1;

if ($numArgs != 1
	|| $ARGV[0] !~ /^slackware(64)?-([0-9]+\.[0-9]+|current){1}$/i) {
	printf("This script takes only one argument - slackwareversion.\n");
	printf("Example: %s slackware64-13.1\n", $0);
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
$template->param(SVER => $sver);
my $title = sprintf("Changelog of %s", $sver);
$template->param(TITLE => $title);

my $fileHtmlOut = sprintf("%s/changelogs/%s/ChangeLog.tmpl", $CFG{TMPDIR},
	$sver);

open(FH_HTML, '>', $fileHtmlOut) or die("Unable to open HTML out-file.");
print FH_HTML $template->output();
close(FH_HTML);

my $tagPreOpen = 0;
my $fileChlog = sprintf("%s/%s/ChangeLog.txt", $CFG{TMPDIR}, $sver);
my $fileChlogNew = sprintf("%s/changelogs/%s/ChangeLog.tmp", $CFG{TMPDIR},
	$sver);
open(FH_CHLOG, '<', $fileChlog) or die("Unable to open ChangeLog.");
open(FH_CHLOGNEW, '>', $fileChlogNew) 
	or die("Unable to open ChangeLog for output.");
while (my $line = <FH_CHLOG>) {
	chomp($line);
	if ($line =~ /^[A-Za-z]{3}[\ ]+[A-Za-z]{3}[\ ]+[0-9]{1,2}[\ ]+[0-9]{2}:[0-9]{2}:[0-9]{2}[\ ]+[A-Z]{3,4}[\ ]+[0-9]{4}$/) {
		$line =~ s/(^[A-Za-z]{3}[\ ]+[A-Za-z]{3}[\ ]+[0-9]{1,2}[\ ]+[0-9]{2}:[0-9]{2}:[0-9]{2}[\ ]+[A-Z]{3,4}[\ ]+[0-9]{4}$)/<h5>$1<\/h5><pre>/;
		$tagPreOpen = 1;
		goto PRINTLINE;
	}
	if ($line =~ /^[\-]+$/) {
		$line =~ s/^[\-]+$/<\/pre><hr \/>/;
		$tagPreOpen = 0;
		goto PRINTLINE;
	}	
	if ($line =~ /^\+[\-]+\+$/) {
		$line =~ s/^\+[\-]+\+$/<\/pre><hr \/>/;
		$tagPreOpen = 0;
		goto PRINTLINE;
	}
	$line =~ s/</&lt;/g;
	$line =~ s/>/&gt;/g;
	$line =~ s/&/&#38;/g;
	if ($tagPreOpen == 0) {
		printf(FH_CHLOGNEW "<pre>\n");
		$tagPreOpen = 1;
	}
	PRINTLINE:
	printf(FH_CHLOGNEW, "%s\n", $line);
} # while my $lineChlog
if ($tagPreOpen == 1) {
	printf(FH_CHLOGNEW "</pre>\n");
}
close(FH_CHLOG);
close(FH_CHLOGNEW);

