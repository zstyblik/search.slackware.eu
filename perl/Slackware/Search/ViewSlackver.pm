package Slackware::Search::ViewSlackver;

use strict;
use warnings;

use base 'Slackware::Search::MainWeb';
use CGI::Application::Plugin::Routes;

sub setup {
	my $self = shift;
	$self->start_mode('view_slackver');
	$self->error_mode('error');
	$self->header_props(-type => 'text/html', -charset => 'UTF-8');
	$self->routes_root('/');
	$self->routes([
			'' => 'noview',
			'/view/:slackver' => 'view_slackver',
	]);
} # sub setup

sub cgiapp_init {
	my $self = shift;

	my %CFG = $self->cfg;

	$self->tmpl_path([$CFG{'TMPL_PATH'}]);

	$self->dbh_config(
		$CFG{'DB_DSN'},
		$CFG{'DB_USER'},
		$CFG{'DB_PASS'},
	);
} # sub cgiapp_init

sub view_slackver {
	my $self = shift;
	my $dbh = $self->dbh;
	my $q = $self->query;
	my $slackver = $q->param('slackver');
	my $validSlackver = $self->_validate_slackver($slackver);
	unless ($validSlackver) {
		return $self->error("Slackversion is garbage.");
	}
	my $idSlackver = $self->_get_slackver_id($slackver);
	unless ($idSlackver) {
		return $self->error("Slackversion is not in DB.");
	}
	my $sql100 = sprintf("SELECT category_name FROM category WHERE \
		id_category IN (SELECT id_category FROM packages WHERE \
		id_slackversion = %i);", $idSlackver);

	my @items;
	my %item = (VALUE => 'foo');
	push(@items, \%item);
	my $template = $self->load_tmpl("index.htm");
	my $title = sprintf("Browsing %s", $slackver);
	$template->param(TITLE => $title);
	$template->param(SLACKVERBRWS => 1);
	$template->param(NAVIGATION => 'navigation');
	return $template->output();
}

1;
