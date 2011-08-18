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
	
	$self->SUPER::cgiapp_prerun;
} # sub cgiapp_init

sub view_slackver {
	my $self = shift;
	my $dbh = $self->dbh;
	my $q = $self->query;
	my $slackver = $q->param('slackver');
	my $validSlackver = $self->_validate_slackver($slackver);
	unless ($validSlackver) {
		return $self->error("Slackversion is garbage.", '/cgi-bin/search.cgi');
	}
	my $idSlackver = $self->_get_slackversion_id($slackver);
	unless ($idSlackver) {
		return $self->error("Slackversion is not in DB.");
	}
	my $sql100 = sprintf("SELECT category_name FROM category WHERE \
		id_category IN (SELECT id_category FROM packages WHERE \
		id_slackversion = %i) ORDER BY category_name ASC;", 
		$idSlackver);
	my $result100 = $dbh->selectall_arrayref($sql100, { Slice => {} });
	unless ($result100) {
		my $errorMsg = sprintf("Unable to select categories for '%s'.", 
			$slackver);
		return $self->error($errorMsg, '/cgi-bin/search.cgi');
	}
	
	if (@$result100 == 0) {
		my $errorMsg = sprintf("No categories were found for '%s'.", 
			$slackver);
		return $self->error($errorMsg, '/cgi-bin/search.cgi');
	}

	my @items;
	my %levelUp = (VALUE => "<a href=\"/cgi-bin/search.cgi\">..</a><br />");
	push(@items, \%levelUp);
	for my $row (@$result100) {
		my $link = sprintf("/cgi-bin/category.cgi/view/%s/%s", $slackver,
			$row->{category_name});
		my $HTML = sprintf("<a href=\"%s\">%s</a><br />", $link,
			$row->{category_name});
		my %item = (VALUE => $HTML);
		push(@items, \%item);
	}

	my $template = $self->load_tmpl("index.htm");
	my $title = sprintf("Browsing %s", $slackver);
	$template->param(TITLE => $title);
	$template->param(SLACKVERBRWS => 1);
	my $navigation = sprintf("%s/", $slackver);
	$template->param(NAVIGATION => $navigation );
	$template->param(ITEMS => \@items);
	my $idSlackverStable = $self->_get_slackversion_idStable();
	$template->param(SVERSTABLE => $idSlackverStable);
	my $slackverStable = $self->_get_slackversion_name($idSlackverStable);
	$template->param(SVERNAME => $slackverStable);
	return $template->output();
}

1;
