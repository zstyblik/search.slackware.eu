package Slackware::Search::MainWeb;

use strict;
use warnings;

use base 'CGI::Application';
use CGI::Application::Plugin::ConfigAuto (qw/cfg/);
use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use CGI::Application::Plugin::Redirect;

sub error {
	my $self = shift;
	my $error = shift;
	my $redir = shift || $ENV{'SCRIPT_NAME'};
	my $template = $self->load_tmpl('index.htm');
	$template->param(ERROR => $error);
	$template->param(REDIRECT => $redir);
	return $template->output();
} # sub error

sub teardown {
	my $self = shift;
	my $dbh = $self->dbh;
	$dbh->disconnect() if ($dbh);
} # sub teardown

1;
