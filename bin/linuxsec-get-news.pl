#!/usr/bin/perl

use strict;
use warnings;
use LWP;

my $url = 'http://www.linuxsecurity.com/static-content/linuxsecurity_advisories.rss';

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
		$printOut.= sprintf("\t\t\t\t\t<li><a href=\"%s\">%s</a></li>\n", 
			$rssLine, $title);
		$title = undef;
		$newsCount++;
	}
} # for my $rssLine

exit 2 if ($newsCount == 0);

# TODO ~ does directory exist?

open(FILE, '>/mnt/tmp/search.slack/news/linuxsec-news.htm');
print FILE "\t\t\t<div class=\"remoteNews-right\">\n";
print FILE "\t\t\t\t<ul>\n";
print FILE $printOut;
print FILE "\t\t\t\t</ul>\n";
print FILE "\t\t\t</div>\n";
close(FILE);
