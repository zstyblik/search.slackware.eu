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

my $url = "http://www.slackware.com/getslack/torrents.php";
my $baseURL = 'http://www.slackware.com/torrents/';
my $outDir = '/mnt/tmp/search.slack/news/';

my $browser = LWP::UserAgent->new;
my $printOut = '';

my $response = $browser->get( $url ) 
	or die("Unable to get URL '$url'");
die ("Unable to get URL '$url'.") if ($response->is_error());
for my $htmlLine ( split(/\n/, $response->content) ) {
	chomp($htmlLine);
	$htmlLine =~ s/^\s+//;
	$htmlLine =~ s/\s+$//;
	if ($htmlLine =~ /\.torrent/) {
		$htmlLine = substr($htmlLine, index($htmlLine, "<a href="), 
			index($htmlLine, "</a>")+4 );
		$htmlLine =~ s/\/torrents\//$baseURL/;
		$printOut.= sprintf("\t\t\t\t\t\t<li>%s</li>\n", $htmlLine);
	}
} # for my $htmlLine

unless ( -e $outDir ) {
	exit 254;
}

my $outFile = sprintf("%s/slack-torrents.htm", $outDir);

open(FH_F, '>', $outFile) or die("Unable to write to file '$outFile'. $!");
printf(FH_F "\t\t\t<div class=\"remoteNews\">\n");
printf(FH_F "\t\t\t\t<fieldset>\n");
printf(FH_F "\t\t\t\t\t<legend>Slackware torrents</legend>\n");
printf(FH_F "\t\t\t\t\t<ul>\n");
printf(FH_F "%s", $printOut);
printf(FH_F "\t\t\t\t\t</ul>\n");
printf(FH_F "\t\t\t</div>\n");
close(FH_F) or die("Unable to close file handler. $!");
