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
package Slackware::Search::ViewPackage;

use strict;
use warnings;

use base 'Slackware::Search::MainWeb';
use CGI::Application::Plugin::Routes;

SUB Setup {
	my $self = shift;
	$self->start_mode('view');

	$self->header_props(-type => 'text/html', -charset => 'UTF-8');
	# routes_root optionally is used to prepend a URI part to 
	# every route
	$self->routes_root('/'); 
	$self->routes([
		'' => 'noview',
		'/download/:slackver/:category/:serie/:package/:country' => 'download',
		'/inspect/:slackver/:category/:serie/:package' => 'inspect',
		'/view/:slackver/:category/:serie/:package' => 'view',
	]);

} # sub setup

sub cgiapp_init {
	my $self = shift;
	
	$self->SUPER::cgiapp_prerun;
} # sub cgiapp_prerun

# desc: choose mirror in specified country where to download from
sub download {
	my $self = shift;
	my $q = $self->query();

	# get params
	my $slackver = $q->param('slackver');
	my $category = $q->param('category');
	my $serie = $q->param('serie');
	my $package = $q->param('package');
	my $country = $q->param('country');
	# validate/sanitize input
	my $validSlackver = $self->_validate_slackver($slackver);
	unless ($validSlackver) {
		return $self->error("Slackware version is garbage.", 
			'/cgi-bin/search.cgi');
	}
	my $validCategory = $self->_validate_category($category);
	unless ($validCategory) {
		return $self->error("Category is garbage.", '/cgi-bin/search.cgi');
	}
	$serie =~ $self->_url_decode($serie);
	$serie =~ s/@+/\//g;
	my $validSerie = $self->_validate_serie($serie);
	unless ($validSerie) {
		return $self->error("Serie is garbage.", '/cgi-bin/search.cgi');
	}
	my $validPackage = $self->_validate_package($package);
	unless ($validPackage) {
		return $self->error("Package is garbage.", '/cgi-bin/search.cgi');
	}
	$country =~ $self->_url_decode($country);
	unless ($country =~ /^[A-Za-z\ ]+$/) {
		return $self->error("Wrong country.".$country, '/cgi-bin/search.cgi');
	}
	# does slackver exist? fast lookup
	my $idSlackver = $self->_get_slackversion_id($slackver);
	unless ($idSlackver) {
		return $self->error("Slackware version is not in DB.", 
			'/cgi-bin/search.cgi');
	}
	# does category exist? fast lookup
	my $idCategory = $self->_get_category_id($category, $idSlackver);
	unless ($idCategory) {
		return $self->error("Category is not in DB.", '/cgi-bin/search.cgi');
	}
	# does serie exist? fast lookup
	my $idSerie = $self->_get_serie_id($serie);
	unless ($idSerie) {
		return $self->error("Serie is not in DB.", '/cgi-bin/search.cgi');
	}
	# does country exist?
	my $idCountry = $self->_get_country_id($country);
	unless ($idCountry) {
		return $self->error("Country is not in DB.", '/cgi-bin/search.cgi');
	}
	# does pkg exist? slow lookup
	my $idPkgs = $self->_get_packages_id($package, $idCategory, $idSlackver);
	unless ($idPkgs) {
		return $self->error("Package is not in DB.", '/cgi-bin/search.cgi');
	}

	my $pkgDetail = $self->_get_pkg_details($idPkgs);
	unless ($pkgDetail) {
		return $self->error("It looks like this package doesn't \
			exist.", '/cgi-bin/search.cgi');
	}

	my $template = $self->load_tmpl('index.htm');
	$template->param(TITLE => $pkgDetail->{PKGNAME});
	$template->param(PKG => 1);
	$template->param(COUNTRY => $country);

	for my $value (keys(%$pkgDetail)) {
		$template->param($value => $pkgDetail->{$value});
	}

	my $pkgPath = "/".$pkgDetail->{PKGSVER}."/".$pkgDetail->{PKGCAT}
	."/".$pkgDetail->{PKGSER}."/".$pkgDetail->{PKGNAME};
	my @mirrors = $self->_get_mirrors($idCountry, $pkgPath);
	$template->param(MIRRORS => \@mirrors);

	my $serieEnc = $pkgDetail->{PKGSER};
	$serieEnc =~ s/\/+/@/g;
	$serieEnc =~ $self->_url_encode($serie);
	my $pkgURLPath = sprintf("%s/view/%s/%s/%s/%s", $ENV{SCRIPT_NAME}, 
		$pkgDetail->{PKGSVER}, 
		$pkgDetail->{PKGCAT}, $serieEnc, $pkgDetail->{PKGNAME});
	$pkgURLPath =~  s/\/\//\//so;

	$template->param(SWURL => $pkgURLPath);
	$template->param(SWLABEL => "Choose another location");
	my $idSlackverStable = $self->_get_slackversion_idStable();
	$template->param(SVERSTABLE => $idSlackverStable);
	my $slackverStable = $self->_get_slackversion_name($idSlackverStable);
	$template->param(SVERNAME => $slackverStable);
	return $template->output();
} # sub download

# '/inspect/:slackver/:category/:package'
sub inspect {
	my $self = shift;
	my $q = $self->query();

	# get params
	my $slackver = $q->param('slackver');
	my $category = $q->param('category');
	my $serie = $q->param('serie');
	my $package = $q->param('package');
	# validate/sanitize input
	my $validSlackver = $self->_validate_slackver($slackver);
	unless ($validSlackver) {
		return $self->error("Slackware version is garbage.", 
			'/cgi-bin/search.cgi');
	}
	my $validCategory = $self->_validate_category($category);
	unless ($validCategory) {
		return $self->error("Category is garbage.", '/cgi-bin/search.cgi');
	}
	$serie =~ $self->_url_decode($serie);
	$serie =~ s/@+/\//g;
	my $validSerie = $self->_validate_serie($serie);
	unless ($validSerie) {
		return $self->error("Serie is garbage.", '/cgi-bin/search.cgi');
	}
	my $validPackage = $self->_validate_package($package);
	unless ($validPackage) {
		return $self->error("Package is garbage.", '/cgi-bin/search.cgi');
	}
	# does slackver exist? fast lookup
	my $idSlackver = $self->_get_slackversion_id($slackver);
	unless ($idSlackver) {
		return $self->error("Slackware version is not in DB.", 
			'/cgi-bin/search.cgi');
	}
	# does category exist? fast lookup
	my $idCategory = $self->_get_category_id($category, $idSlackver);
	unless ($idCategory) {
		return $self->error("Category is not in DB.", '/cgi-bin/search.cgi');
	}
	# does serie exist? fast lookup
	my $idSerie = $self->_get_serie_id($serie);
	unless ($idSerie) {
		return $self->error("Serie is not in DB.", '/cgi-bin/search.cgi');
	}
	# does pkg exist? slow lookup
	my $idPkgs = $self->_get_packages_id($package, $idCategory, $idSlackver);
	unless ($idPkgs) {
		return $self->error("Package is not in DB.", '/cgi-bin/search.cgi');
	}

	my $pkgDetail = $self->_get_pkg_details($idPkgs);
	unless ($pkgDetail) {
		return $self->error("It looks like this package doesn't \
			exist.", '/cgi-bin/search.cgi');
	}

	my $template = $self->load_tmpl('index.htm');
	$template->param(TITLE => $pkgDetail->{PKGNAME});
	$template->param(PKG => 1);

	for my $value (keys(%$pkgDetail)) {
		$template->param($value => $pkgDetail->{$value});
	}

	my @pkgFiles = $self->_get_pkg_files($idPkgs, 
		$pkgDetail->{PKGSVER});

	unless (@pkgFiles == 0) {
		$template->param(PKGFILES => \@pkgFiles);
	}
	my $serieEnc = $pkgDetail->{PKGSER};
	$serieEnc =~ s/\/+/@/g;
	$serieEnc =~ $self->_url_encode($serie);
	my $pkgURLPath = sprintf("%s/view/%s/%s/%s/%s", $ENV{SCRIPT_NAME}, 
		$pkgDetail->{PKGSVER}, 
		$pkgDetail->{PKGCAT}, $serieEnc, $pkgDetail->{PKGNAME});
	$pkgURLPath =~  s/\/\//\//so;

	$template->param(SWURL => $pkgURLPath);
	$template->param(SWLABEL => "Download");
	my $idSlackverStable = $self->_get_slackversion_idStable();
	$template->param(SVERSTABLE => $idSlackverStable);
	my $slackverStable = $self->_get_slackversion_name($idSlackverStable);
	$template->param(SVERNAME => $slackverStable);
	return $template->output();
} # sub inspect

# desc: view sink hole
sub noview {
	my $self = shift;
	return $self->error("Some of parameters are missing.", 
		'/cgi-bin/search.cgi');
}

# '/view/:slackver/:category/:package' => view,
sub view {
	my $self = shift;
	my $q = $self->query();

	# get params
	my $slackver = $q->param('slackver');
	my $category = $q->param('category');
	my $serie = $q->param('serie');
	my $package = $q->param('package');
	# validate/sanitize input
	my $validSlackver = $self->_validate_slackver($slackver);
	unless ($validSlackver) {
		return $self->error("Slackware version is garbage.", 
			'/cgi-bin/search.cgi');
	}
	my $validCategory = $self->_validate_category($category);
	unless ($validCategory) {
		return $self->error("Category is garbage.", '/cgi-bin/search.cgi');
	}
	$serie =~ $self->_url_decode($serie);
	$serie =~ s/@+/\//g;
	my $validSerie = $self->_validate_serie($serie);
	unless ($validSerie) {
		return $self->error("Serie is garbage.", '/cgi-bin/search.cgi');
	}
	my $validPackage = $self->_validate_package($package);
	unless ($validPackage) {
		return $self->error("Package is garbage.", '/cgi-bin/search.cgi');
	}
	# does slackver exist? fast lookup
	my $idSlackver = $self->_get_slackversion_id($slackver);
	unless ($idSlackver) {
		return $self->error("Slackware version is not in DB.", 
			'/cgi-bin/search.cgi');
	}
	# does category exist? fast lookup
	my $idCategory = $self->_get_category_id($category, $idSlackver);
	unless ($idCategory) {
		return $self->error("Category is not in DB.", '/cgi-bin/search.cgi');
	}
	# does serie exist? fast lookup
	my $idSerie = $self->_get_serie_id($serie);
	unless ($idSerie) {
		return $self->error("Serie is not in DB.", '/cgi-bin/search.cgi');
	}
	# does pkg exist? slow lookup
	my $idPkgs = $self->_get_packages_id($package, $idCategory, $idSlackver);
	unless ($idPkgs) {
		return $self->error("Package is not in DB.", '/cgi-bin/search.cgi');
	}

	my $pkgDetail = $self->_get_pkg_details($idPkgs);
	unless ($pkgDetail) {
		return $self->error("It looks like this package doesn't \
			exist.", '/cgi-bin/search.cgi');
	}

	my $template = $self->load_tmpl('index.htm');
	$template->param(TITLE => $pkgDetail->{PKGNAME});
	$template->param(PKG => 1);

	for my $value (keys(%$pkgDetail)) {
		$template->param($value => $pkgDetail->{$value});
	}

	my $serieEnc = $pkgDetail->{PKGSER};
	$serieEnc =~ s/\/+/@/g;
	$serieEnc =~ $self->_url_encode($serie);
	my $pkgURLPath = sprintf("%s/inspect/%s/%s/%s/%s", $ENV{SCRIPT_NAME}, 
		$pkgDetail->{PKGSVER}, 
		$pkgDetail->{PKGCAT}, $serieEnc, $pkgDetail->{PKGNAME});
	$pkgURLPath =~  s/\/\//\//so;

	$template->param(SWURL => $pkgURLPath);
	$template->param(SWLABEL => "Files");

	# Note: the ugliest of ugliest ... you may vomit!
	my @countries = $self->_get_mirror_locations($pkgDetail);
	my @countriesTpl;
	my $country;
	while (1) {
		my %item;
		$country = shift(@countries);
		if ($country) {
			$item{COUNTRY1} = $country->{COUNTRY};
			$item{LINKCOUNTRY1} = $country->{LINKCOUNTRY};
			$item{LINKFLAG1} = $country->{LINKFLAG};
		}

		$country = shift(@countries);
		if ($country) {
			$item{COUNTRY2} = $country->{COUNTRY};
			$item{LINKCOUNTRY2} = $country->{LINKCOUNTRY};
			$item{LINKFLAG2} = $country->{LINKFLAG};
		}
		
		$country = shift(@countries);
		if ($country) {
			$item{COUNTRY3} = $country->{COUNTRY};
			$item{LINKCOUNTRY3} = $country->{LINKCOUNTRY};
			$item{LINKFLAG3} = $country->{LINKFLAG};
		}

		$country = shift(@countries);
		if ($country) {
			$item{COUNTRY4} = $country->{COUNTRY};
			$item{LINKCOUNTRY4} = $country->{LINKCOUNTRY};
			$item{LINKFLAG4} = $country->{LINKFLAG};
		}

		push(@countriesTpl, \%item) if (%item);
		last unless ($country);
	} # while $counter < $countriesSize
	
	$template->param(COUNTRIES => \@countriesTpl);
	my $idSlackverStable = $self->_get_slackversion_idStable();
	$template->param(SVERSTABLE => $idSlackverStable);
	my $slackverStable = $self->_get_slackversion_name($idSlackverStable);
	$template->param(SVERNAME => $slackverStable);

	return $template->output();
} # sub view
# desc: look up if country exists in DB
# $country: string;
# @return: int;
sub _get_country_id {
	my $self = shift;
	my $country = shift || '';
	unless ($country =~ /^[A-Za-z\ ]+$/) {
		return 0;
	}
	my $dbh = $self->dbh;
	my $sql1 = sprintf("SELECT id_country FROM country WHERE 
		name = '%s';", $country);
	my $result1 = $dbh->selectrow_array($sql1);
	return 0 unless $result1;
	return $result1;
}
# desc: return formated list of locations
# $idPkgs: int;
# @return: array;
sub _get_mirror_locations {
	my $self = shift;
	my $pkgDetail = shift;
	my @countries;
	# TODO ~ more checking?
	unless ($pkgDetail) {
		return @countries;
	}

	my $dbh = $self->dbh;
	my $sql1 = "SELECT name, flag_url FROM country WHERE \
		EXISTS(SELECT 1 FROM mirror WHERE id_country = country.id_country);";
	my $result1 = $dbh->selectall_arrayref($sql1, { Slice => {}});

	unless ($result1) {
		return @countries;
	}

	my $serieEnc = $pkgDetail->{PKGSER};
	$serieEnc =~ s/\/+/@/g;
	$serieEnc =~ $self->_url_encode($serieEnc);
	my $link = sprintf("%s/download/%s/%s/%s/%s", $ENV{SCRIPT_NAME}, 
		$pkgDetail->{PKGSVER}, 
		$pkgDetail->{PKGCAT}, $serieEnc, $pkgDetail->{PKGNAME});
	$link =~  s/\/\//\//so;

	while (my $country = shift(@$result1)) {
		my $countryEnc = $country->{name};
		$countryEnc =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
		my $countryURL = sprintf("%s/%s", $link, $countryEnc);
		my %item = (COUNTRY => $country->{name},
			LINKFLAG => $country->{flag_url},
			LINKCOUNTRY => $countryURL,
		);
		push(@countries, \%item);
	}

	return @countries;
} # sub _get_mirror_locations
# desc: return formated list of mirrors for specified location
# $idCountry: integer;
# $pkgPath: string;
# @return: array;
sub _get_mirrors {
	my $self = shift;
	my $idCountry = shift;
	my $pkgPath = shift || undef; 
	my @mirrors;
	unless ($idCountry =~ /^[0-9]+$/) {
		return @mirrors;
	}
	unless ($pkgPath) {
		return @mirrors;
	}
	my $dbh = $self->dbh;
	my $sql1 = sprintf("SELECT * FROM mirror WHERE \
	id_country = %i;", $idCountry);
	my $result1 = $dbh->selectall_arrayref($sql1, { Slice => {}});
	
	unless ($result1) {
		return @mirrors;
	}

	for my $row1 (@$result1) {
		my %item = (MPROTO => $row1->{mirror_proto},
			MDESC => $row1->{mirror_desc},
			MURL => $row1->{mirror_url}.$pkgPath,
		);
		push(@mirrors, \%item);
	}

	return @mirrors;
} # sub _get_mirrors
# desc: return details of specific package
# $idPkgs: int;
# @return: hash ref;
sub _get_pkg_details {
	my $self = shift;
	my $idPkgs = shift;
	unless ($idPkgs =~ /^[0-9]+$/) {
		return undef;
	}
	my $dbh = $self->dbh;
	
	# TODO ~ check out this query
	my $sql1 = "SELECT * FROM view_packages \
	FULL JOIN slackversion \
	ON view_packages.id_slackversion = slackversion.id_slackversion \
	FULL JOIN category ON view_packages.id_category = \
	category.id_category \
	FULL JOIN serie ON view_packages.id_serie = \
	serie.id_serie WHERE id_packages = $idPkgs;";
	my $hashPkg = $dbh->selectrow_hashref($sql1, { Slice => {}});
	unless ($hashPkg) {
		return undef;
	}

	my %pkgDetails;
#	$pkgDetails{IDPKGS} = $hashPkg->{id_packages};
	$pkgDetails{PKGDATE} = $hashPkg->{package_created};
	$pkgDetails{PKGMD5} = $hashPkg->{package_md5sum};
	$pkgDetails{PKGDESC} = $hashPkg->{package_desc};
	$pkgDetails{PKGNAME} = $hashPkg->{package_name};
	$pkgDetails{PKGCAT} = $hashPkg->{category_name};
	$pkgDetails{PKGSVER} = $hashPkg->{slackversion_name};
	$pkgDetails{PKGSER} = '';
	$pkgDetails{PKGSERENC} = '';
	my $serie = '';
	if ($hashPkg->{serie_name}) {
		$pkgDetails{PKGSER} = $hashPkg->{serie_name};
		$serie = $hashPkg->{serie_name};
		my $serieEnc = $self->_url_encode($serie);
		$pkgDetails{PKGSERENC} = $serieEnc;
	}
	return \%pkgDetails;
} # sub _get_pkg_details
# desc: return id_packages
sub _get_packages_id {
	my $self = shift;
	my $package = shift;
	my $idCategory = shift;
	my $idSlackver = shift;

	unless ($self->_validate_package($package)) {
		return 0;
	}
	if ($idCategory !~ /^[0-9]+$/) {
		return 0;
	}
	if ($idSlackver !~ /^[0-9]+$/) {
		return 0;
	}
	my $dbh = $self->dbh;
	my $sql1 = sprintf("SELECT id_package FROM package WHERE 
		package_name = '%s';", $package);
	my $result1 = $dbh->selectrow_array($sql1);
	return 0 unless $result1;

	my $sql2 = sprintf("SELECT id_packages FROM packages WHERE 
		id_package = %i AND id_category = %i AND id_slackversion = %i;", 
		$result1, $idCategory, $idSlackver);
	# TODO ~ this probably should be selectall_arrayref and check whether 
	# only one package got returned ... right?
	my $result2 = $dbh->selectrow_array($sql2);
	return 0 unless $result2;
	return $result2;
} # sub _get_packages_id
# desc: return formated list of files associated with package
# $idPkgs: int;
# $slackver: string;
# @return: array;
sub _get_pkg_files {
	my $self = shift;
	my $idPkgs = shift;
	my $slackver = shift;
	my @filesFound;

	unless ($idPkgs =~ /^[0-9]+$/) {
		return @filesFound;
	}

	unless ($slackver =~ /^slackware[A-Za-z0-9\-\.]+$/) {
		return @filesFound;
	}

	my %CFG = %{ $self->param('CONFIG') };
	my $sqlitePath = $CFG{'SQLITE_PATH'};
	my $sqLiteFile = $sqlitePath."/".$slackver.".sq3";
	unless ( -e $sqLiteFile ) {
		return @filesFound;
	}

	my $dbhLite = DBI->connect("dbi:SQLite:dbname=".$sqLiteFile, 
		"","", 
		{ AutoCommit => 1,
			PrintError => 0,
			RaiseError => 0
		}
	);
	unless ($dbhLite) {
		return @filesFound;
	}

	my $sql1 = "SELECT file_name, file_size, file_created, \
	file_acl, file_owner  FROM files WHERE id_packages = $idPkgs;";
	my $arrFiles = $dbhLite->selectall_arrayref($sql1, 
		{ Slice => {}});
	$dbhLite->disconnect;
	unless ($arrFiles) {
		return @filesFound;
	}

	for my $row1 (@$arrFiles) {
		my $line = sprintf("%s\t%s\t%10i\t%s\t%s\n", $row1->{file_acl}, 
			$row1->{file_owner}, $row1->{file_size}, 
			$row1->{file_created}, $row1->{file_name});
		my %item = (FILE => $line,);
		push(@filesFound, \%item);
	}

	return @filesFound;
} # sub _get_pkg_details

1;
