#!/usr/bin/perl
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
use LWP;
use Time::Local;

my $url = "http://www.slackware.com/lists/archive/"
."list.php?l=slackware-security&y=YYY";
my $baseURL = 'http://www.slackware.com/lists/archive/viewer.php';
my $outDir = '/mnt/tmp/search.slack/news/';

my ($sec,$min,$hour,$day,$month,$year,$wday,$yday,$isdst) = 
	localtime(time);
$year = 1900 + $year;
my $yearStop = $year - 1;

my $browser = LWP::UserAgent->new;
my $newsCount = 0;
my $printOut = '';

while ($year >= $yearStop) {
	my $link = $url;
	$link =~ s/YYY/$year/;
	my $response = $browser->get( $link ) 
		or die("Unable to get URL '$link'");
	die ("Unable to get URL '$link'.") if ($response->is_error());
	for my $htmlLine ( split(/\n/, $response->content) ) {
		chomp($htmlLine);
		$htmlLine =~ s/^\s+//;
		$htmlLine =~ s/\s+$//;
		if ($htmlLine =~ /viewer\.php/) {
			$htmlLine = substr($htmlLine, index($htmlLine, $year."-"), 
				length($htmlLine));
			$htmlLine =~ s/\[slackware-security\]//;
			$htmlLine =~ s/A HREF/a href/;
			$htmlLine =~ s/&/&#38;/g;
			$htmlLine =~ s/viewer\.php/$baseURL/;
			$newsCount++;
			$printOut.= sprintf("\t\t\t\t\t\t<li>%s</a></li>\n", $htmlLine);
		}
		if ($newsCount >= 10) {
			$year = 0;
			last;
		}
	} # for my $htmlLine
	$year--;
}

exit 2 if ($newsCount == 0);

unless ( -e $outDir ) {
	exit 254;
}

my $outFile = sprintf(">%s/slack-news.htm", $outDir);

open(FILE, $outFile) or die("Unable to write to file.");
print FILE "\t\t\t<div class=\"remoteNews-left\">\n";
print FILE "\t\t\t\t<fieldset>\n";
print FILE "\t\t\t\t\t<legend>Slackware security warnings</legend>\n";
print FILE "\t\t\t\t\t<ul>\n";
print FILE $printOut;
print FILE "\t\t\t\t\t</ul>\n";
print FILE "\t\t\t\t\t<div class=\"remoteNews-source\">\n";
print FILE "\t\t\t\t\t\t--source <a href=\"http://www.slackware.com/security/\">slackware.com</a>\n";
print FILE "\t\t\t\t\t</div>\n";
print FILE "\t\t\t\t</fieldset>\n";
print FILE "\t\t\t</div>\n";
close(FILE);
