#!/usr/bin/perl -wT
use strict;
use CGI::Carp qw(fatalsToBrowser);
use lib '/srv/httpd/search.slackware.eu/perl/';
use Slackware::Search::FinderCLI;
my $webapp = Slackware::Search::FinderCLI->new(
	PARAMS => {
		cfg_file => ['/srv/httpd/search.slackware.eu/conf/config.pl'],
		format => 'perl',
	},
);
$webapp->run();
