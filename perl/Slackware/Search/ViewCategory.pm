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
	
	$self->SUPER::cgiapp_prerun;
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
		return $self->error("Slackversion is garbage", '/cgi-bin/search.cgi');
	}
	my $validCategory = $self->_validate_category($category);
	unless ($validCategory) {
		my $backLink = sprintf("/cgi-bin/slackver.cgi/view/%s", $slackver);
		return $self->error("Category is garbage.", $backLink);
	}
	# look-up in DB
	my $idSlackver = $self->_get_slackversion_id($slackver);
	unless ($idSlackver) {
		return $self->error("Slackversion is not in DB.", '/cgi-bin/search.cgi');
	}
	my $idCategory = $self->_get_category_id($category);
	unless ($idCategory) {
		my $backLink = sprintf("/cgi-bin/slackver.cgi/view/%s", $slackver);
		return $self->error("Category is not in DB.", $backLink);
	}
	my $sql100 = sprintf("SELECT serie_name FROM serie WHERE \
		id_serie IN (SELECT id_serie FROM packages WHERE id_slackversion = %i \
		AND id_category = %i) ORDER BY serie_name ASC;", $idSlackver, 
		$idCategory);
	my $result100 = $dbh->selectall_arrayref($sql100, { Slice => {} });

	unless ($result100) {
		my $errorMsg = sprintf("Unable to select series from '%s/%s'.", 
			$slackver, $category);
		my $backLink = sprintf("/cgi-bin/slackver.cgi/view/%s", $slackver);
		return $self->error($errorMsg, $backLink);
	}

	if (@$result100 == 0) {
		my $errorMsg = sprintf("No series were found under '%s/%s'.", 
			$slackver, $category);
		my $backLink = sprintf("/cgi-bin/slackver.cgi/view/%s", $slackver);
		return $self->error($errorMsg, $backLink);
	}

	my @items;
	my $levelUpLink = sprintf("<a href=\"/cgi-bin/slackver.cgi/view/%s\">..</a><br/>",
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
	my $slackverLink = sprintf("<a href=\"/cgi-bin/slackver.cgi/view/%s\">%s</a>", 
		$slackver, $slackver);
	my $navigation = sprintf("%s/%s/", $slackverLink, $category);
	$template->param(NAVIGATION => $navigation);
	$template->param(ITEMS => \@items);
	my $idSlackverStable = $self->_get_slackversion_idStable();
	$template->param(SVERSTABLE => $idSlackverStable);
	my $slackverStable = $self->_get_slackversion_name($idSlackverStable);
	$template->param(SVERNAME => $slackverStable);
	return $template->output();
}

1;
