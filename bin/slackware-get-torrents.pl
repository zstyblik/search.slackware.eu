#!/usr/bin/perl

use strict;
use warnings;
use LWP;
use Time::Local;

my $url = "http://www.slackware.com/getslack/torrents.php";
my $baseURL = 'http://www.slackware.com/torrents/';

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
		$printOut.= sprintf("\t\t\t\t\t<li>%s</li>\n", $htmlLine);
	}
} # for my $htmlLine

open(FILE, '>/mnt/tmp/czslug.org/slack-torrents.htm');
print FILE "\t\t\t<div class=\"remoteNews-left\">\n";
print FILE "\t\t\t\t<ul>\n";
print FILE $printOut;
print FILE "\t\t\t\t</ul>\n";
print FILE "\t\t\t</div>\n";
close(FILE);
