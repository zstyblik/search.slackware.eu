package Slackware::Search::ViewSerie;

use strict;
use warnings;

use base 'Slackware::Search::MainWeb';
use CGI::Application::Plugin::Routes;

sub setup {
	my $self = shift;
	$self->start_mode('view_serie');
	$self->error_mode('error');
	$self->header_props(-type => 'text/html', -charset => 'UTF-8');
	$self->routes_root('/');
	$self->routes([
			'' => 'noview',
			'/view/:slackver/:category/:serie' => 'view_serie',
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

sub view_serie {
	my $self = shift;
	my $dbh = $self->dbh;
	my $q = $self->query;
	my $slackver = $q->param('slackver');
	my $category = $q->param('category');
	my $serie = $q->param('serie');
	my $validSlackver = $self->_validate_slackver($slackver);
	unless ($validSlackver) {
		return $self->error("Slackversion is garbage.");
	}
	my $validCategory = $self->_validate_category($category);
	unless ($validCategory) {
		return $self->error("Category is garbage.");
	}
	my $validSerie = $self->_validate_serie($serie);
	unless ($validSerie) {
		return $self->error("Serie is garbage.");
	}
	my $idSlackver = $self->_get_slackver_id($slackver);
	unless ($idSlackver) {
		return $self->error("Slackversion is not in DB.");
	}
	my $idCategory = $self->_get_category_id($category);
	unless ($idCategory) {
		return $self->error("Category is not in DB.");
	}
	my $idSerie = $self->_get_serie_id($serie);
	unless ($idSerie) {
		return $self->error("Serie is not in DB.");
	}
	my $sql100 = sprintf("SELECT package_name FROM package WHERE id_package 
		IN  (SELECT id_package FROM packages WHERE id_slackversion = %i AND 
		id_category = %i AND id_serie = %i);", $idSlackver, $idCategory, 
		$idSerie);
}

1;
