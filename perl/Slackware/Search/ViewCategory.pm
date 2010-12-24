package Slackware::Search::ViewCategory;

use strict;
use warnings;

use base 'Slackware::Search::MainWeb';
use CGI::Application::Plugin::Routes;

sub setup {
	my $self = shift;
	$self->start_mode('view_category');
	$self->error_mode('error');
	$self->header_props(-type => 'text/html', -charset => 'UTF-8');
	$self->routes_root('/');
	$self->routes([
			'' => 'noview',
			'/view/:slackver/:category' => 'view_category',
	]);
} # sub setup

sub cgiapp_init {
	my $self = shift;

	my %CFG = $self->cfg;

	$self->tmpl_patch([$CFG{'TMPL_PATH'}]);

	$self->dbh_config(
		$CFG{'DB_DSN'},
		$CFG{'DB_USER'},
		$CFG{'DB_PASS'},
	);
} # sub cgiapp_init

sub view_category {
	my $self = shift;
	my $q = $self->query;
	my $sql100 = sprintf("SELECT serie_name FROM serie WHERE \
		id_serie IN (SELECT id_serie FROM packages WHERE id_slackversion = %i \
		AND id_category = %i);", $idSlackver, $idCategory);
}

1;
