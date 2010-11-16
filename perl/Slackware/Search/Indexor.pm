package Slackware::Search::Indexor;

use strict;
use warnings;

use base 'CGI::Application';
use CGI::Application::Plugin::Routes;
use CGI::Application::Plugin::ConfigAuto	(qw/cfg/);
#use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use CGI::Application::Plugin::Redirect;

sub setup {
	my $self = shift;
	$self->start_mode('about');

	$self->header_props(-type => 'text/html', -charset => 'UTF-8');
	# routes_root optionally is used to prepend a URI part to 
	# every route
	$self->routes_root('/'); 
	$self->routes([
		'' => 'about' ,
		'/about' => 'about',
		'/links' => 'links',
	]);
}

sub cgiapp_init {
	my $self = shift;

	my %CFG = $self->cfg;

	$self->tmpl_path([$CFG{'TMPL_PATH'}]);

  # open database connection
#	$self->dbh_config(
#    $CFG{'DB_DSN'},
#    $CFG{'DB_USER'},
#    $CFG{'DB_PASS'},
#  );
} # sub cgiapp_prerun

sub teardown {
	my $self = shift;
#	my $dbh = $self->dbh;
#	$dbh->disconnect();
} # sub teardown

sub error {
	my $self = shift;
	my $error = shift;
	my $redir = shift || $ENV{'SCRIPT_NAME'};
	my $template = $self->load_tmpl('error.htm');
	$template->param(ERROR => $error);
	$template->param(REDIRECT => $redir);
	return $template->output();
} # sub error

sub about {
	my $self = shift;
	my $template = $self->load_tmpl("index.htm");
	$template->param(TITLE => "About");
	$template->param(ABOUT => 1);
	return $template->output();
}

sub links {
	my $self = shift;
	my $template = $self->load_tmpl("index.htm");
	$template->param(TITLE => "Links");
	$template->param(LINKS => 1);
	return $template->output();
}

1;
