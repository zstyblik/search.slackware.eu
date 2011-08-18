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

my $url = 'http://www.linuxsecurity.com/static-content/linuxsecurity_advisories.rss';
my $outDir = '/mnt/tmp/search.slack/news/';

my $browser = LWP::UserAgent->new;

my $response = $browser->get( $url ) 
	or die("Unable to get URL '$url'");
die ("Unable to get URL '$url'.") if ($response->is_error());

my ($link, $title);
my $printOut = '';
my $newsCount = 0;
my $firstTitle = 1;
for my $rssLine ( split(/\n/, $response->content) ) {
	chomp($rssLine);
	$rssLine =~ s/^\s+//;
	$rssLine =~ s/\s+$//;
	if ( $rssLine =~ /^<title>/ ) {
		$rssLine =~ s/<(\/)?title>//g;
		if ($firstTitle == 1) {
			$firstTitle = 0;
			next;
		}
		$title = $rssLine;
	}
	if ( $title && $rssLine =~ /^<link>/) {
		$rssLine =~ s/<(\/)?link>//g;
		$rssLine =~ s/&/&#38;/g;
		$printOut.= sprintf("\t\t\t\t\t\t<li><a href=\"%s\">%s</a></li>\n", 
			$rssLine, $title);
		$title = undef;
		$newsCount++;
	}
} # for my $rssLine

exit 2 if ($newsCount == 0);

unless ( -e $outDir ) {
	exit 254;
}

my $outFile = sprintf(">%s/linuxsec-news.htm", $outDir);

open(FILE, $outFile) or die("Unable write to file.");
print FILE "\t\t\t<div class=\"remoteNews-right\">\n";
print FILE "\t\t\t\t<fieldset>\n";
print FILE "\t\t\t\t\t<legend>Linux Security headlines</legend>\n";
print FILE "\t\t\t\t\t<ul>\n";
print FILE $printOut;
print FILE "\t\t\t\t\t</ul>\n";
print FILE "\t\t\t\t\t<div class=\"remoteNews-source\">\n";
print FILE "\t\t\t\t\t\t--source <a href=\"$url\">linuxsecurity.com</a>\n";
print FILE "\t\t\t\t\t</div>\n";
print FILE "\t\t\t\t</fieldset>";
print FILE "\t\t\t</div>\n";
close(FILE);
