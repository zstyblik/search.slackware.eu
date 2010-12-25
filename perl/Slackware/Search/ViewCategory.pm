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

	$self->tmpl_path([$CFG{'TMPL_PATH'}]);

	$self->dbh_config(
		$CFG{'DB_DSN'},
		$CFG{'DB_USER'},
		$CFG{'DB_PASS'},
	);
} # sub cgiapp_init

sub view_category {
	my $self = shift;
	my $dbh = $self->dbh;
	my $q = $self->query;
	# get params
	my $slackver = $q->param('slackver');
	my $category = $q->param('category');
	# validate
	my $validSlackver = $self->_validate_slackver($slackver);
	unless ($validSlackver) {
		return $self->error("Slackversion is garbage");
	}
	my $validCategory = $self->_validate_category($category);
	unless ($validCategory) {
		return $self->error("Category is garbage.");
	}
	# look-up in DB
	my $idSlackver = $self->_get_slackver_id($slackver);
	unless ($idSlackver) {
		return $self->error("Slackversion is not in DB.");
	}
	my $idCategory = $self->_get_category_id($category);
	unless ($idCategory) {
		return $self->error("Category is not in DB.");
	}
	my $sql100 = sprintf("SELECT serie_name FROM serie WHERE \
		id_serie IN (SELECT id_serie FROM packages WHERE id_slackversion = %i \
		AND id_category = %i);", $idSlackver, $idCategory);
	my $result100 = $dbh->selectall_arrayref($sql100, { Slice => {} });

	unless ($result100) {
		my $errorMsg = sprintf("Unable to select series from '%s/%s'.", 
			$slackver, $category);
		return $self->error($errorMsg);
	}

	if (@$result100 == 0) {
		my $errorMsg = sprintf("No series were found under '%s/%s'.", 
			$slackver, $category);
		return $self->error($errorMsg);
	}

	my @items;
	my $levelUpLink = sprintf("<a href=\"/cgi-bin/slackver.cgi/view/%s\">
		..</a><br/>",
		$slackver);
	my %levelUp = (VALUE => $levelUpLink);
	push(@items, \%levelUp);
	for my $row (@$result100) {
		my $serieEnc = $row->{serie_name};
		$serieEnc =~ s/\/+/@/g;
		$serieEnc = $self->_url_encode($serieEnc);
		my $link = sprintf("/cgi-bin/serie.cgi/view/%s/%s/%s", $slackver,
			$category, $serieEnc);
		my $HTML = sprintf("<a href=\"%s\">%s</a><br />", $link,
			$row->{serie_name});
		my %item = (VALUE => $HTML);
		push(@items, \%item);
	}
	my $template = $self->load_tmpl("index.htm");
	my $title = sprintf("Browsing %s/%s", $slackver, $category);
	$template->param(TITLE => $title);
	$template->param(SLACKVERBRWS => 1);
	my $slackverLink = sprintf("<a href=\"/cgi-bin/slackver.cgi/view/%s\"
		>%s</a>", $slackver, $slackver);
	my $navigation = sprintf("%s/%s/", $slackverLink, $category);
	$template->param(NAVIGATION => $navigation);
	$template->param(ITEMS => \@items);
	return $template->output();
}

1;
