package Slackware::Search::Finder;

use strict;
use warnings;

use base 'Slackware::Search::MainWeb';
use CGI::Application::Plugin::AutoRunmode;

use constant LIMITFILES => 5;
use constant NEEDLEMINLENGTH => 2;

sub setup {
	my $self = shift;
	$self->start_mode('searchform');
	$self->error_mode('error');
	$self->mode_param(
		path_info => 1,
		param => 'rm',
	);
	$self->header_props(-type => 'text/html', -charset => 'UTF-8');
	$self->run_modes(
		'searchform' => 'search_form',
		'search' => 'search_fetch',
	);
} # sub setup 

# exec the following before we execute the requested run mode
sub cgiapp_init {
	my $self = shift;

	my %CFG = $self->cfg;

	$self->tmpl_path([$CFG{'TMPL_PATH'}]);

  # open database connection
	$self->dbh_config(
    $CFG{'DB_DSN'},
    $CFG{'DB_USER'},
    $CFG{'DB_PASS'},
  );
} # sub cgiapp_prerun

sub search_form: Runmode {
	my $self = shift;
	my $template = $self->load_tmpl("index.htm");
	$template->param(TITLE => "Search");
	$template->param(QSEARCHHIDE => 1);
	$template->param(SEARCH => 1);

	my @slackVersions = $self->_get_slackversions;
	my @categories = $self->_get_categories;

	my @slackVersionsNfo = $self->_get_slackversions_nfo;
	$template->param(SVERNFO => \@slackVersionsNfo);

	$template->param(SVERS => \@slackVersions);
	$template->param(CATS => \@categories);
	$template->param(NEEDLE => '');
	$template->param(HSTACKSELFILES=>'');
	$template->param(HSTACKSELPKGS=>' selected="selected"');
	return $template->output();
} # sub search_form

sub search_fetch: Runmode {
	my $self = shift;
	my $q = $self->query;
	my $timeStart = time;

	unless ($q->param('sver')) {
		return $self->error("Opps! You've tried to pass wrong \
			parameter to the script.");
	}
	my $idSlackver = $q->param('sver');
	unless ($idSlackver =~ /^[0-9]+$/) {
		return $self->error("Opps! You've tried to pass wrong \
			parameter to the script.");
	}

	unless ($q->param('haystack')) {
		return $self->error("Opps! You've tried to pass wrong \
			parameter to the script.");
	}
	my $haystack = $q->param('haystack');
	unless ($haystack =~ /^[0-9]+$/) {
		return $self->error("Opps! You've tried to pass wrong \
			parameter to the script.");
	}

	unless ($q->param('needle')) {
		return $self->error("Opps! You've tried to pass wrong \
			parameter to the script.");
	}
	my $needle = $q->param('needle');
	unless ($needle =~ /^[A-Za-z0-9\-_\.]+$/) {
		return $self->error("Allowed characters for search string \
			are: A-Z, a-z, 0-9, '.', '-' and '_'");
	}
	unless (length($needle) >= NEEDLEMINLENGTH) {
		return $self->error("Search string is too short. Minimum \
			length is ".NEEDLEMINLENGTH);
	}

	my $slackVerName = $self->_get_slackversion_name($idSlackver);
	unless ($slackVerName) {
		return $self->error("This Slackware version doesn't seem \
			to be in DB.");
	}

	my $template = $self->load_tmpl("index.htm");
	$template->param(TITLE => "Search results");
	$template->param(SLACKVER => $slackVerName);
	$template->param(QSEARCHHIDE => 1);
	$template->param(SEARCH => 1);
	$template->param(SEARCHRESULTS => 1);
	$template->param(NEEDLE => $needle);
	$template->param(HSTACKSELFILES=>'');
	$template->param(HSTACKSELPKGS=>'');

	my @slackVersions = $self->_get_slackversions($idSlackver, 
		$slackVerName);
	my @categories = $self->_get_categories;

	my @catsToCheck;
	my @catsToCheckLabels;
	for my $category (@categories) {
		my $catTmp = "cat_".$category->{IDCAT};
		unless ($q->param($catTmp)) {
			next;
		}
		unless ($q->param($catTmp) eq 'on') {
			next;
		}
		push(@catsToCheck, $category->{IDCAT});
		push(@catsToCheckLabels, $category->{CATNAME});
		$category->{CHECKED} = 1;
	}

	$template->param(SVERS => \@slackVersions);
	$template->param(CATS => \@categories);

	my @results;
	my %findParams = (NEEDLE => $needle,
		IDSLACKVER => $idSlackver,
		SLACKVERNAME => $slackVerName,
	);
	
	if ($haystack == 2) {
		$template->param(HSTACKSELPKGS=>' selected="selected"');
		@results = $self->_find_packages(\%findParams, \@catsToCheck);
	} else {
		$template->param(HSTACKSELFILES=>' selected="selected"');
		@results = $self->_find_files(\%findParams, \@catsToCheck);
	}
	unless (@results == 0) {
		$template->param(RESULTS => \@results);
	}

	my $resFound = @results;
	$template->param(RESFOUND => $resFound);

	if (@catsToCheckLabels == 0) {
		$template->param(CATEGORIES => 'ANY');
	} else {
		my $catsChecked = join(", ", @catsToCheckLabels);
		$template->param(CATEGORIES => $catsChecked);
	}	
	if ($haystack == 2) {
		$template->param(HAYSTACK => 'packages');
	} else {
		$template->param(HAYSTACK => 'files');
	}
	
	my $timeStop = time - $timeStart;
	my $timeTaken = int($timeStop % 60);
	$template->param(TIMETAKEN => $timeTaken);
	return $template->output();
} # sub search_fetch
# desc: find packages->files matching $needle in SQLite
# $needle: string;
# $slackver: string;
# $catsToCheck: array ref;
# @return: array;
sub _find_files {
	my $self = shift;
	my $findParams = shift;
	my $catsToCheck = shift; # unused ATM
	my @pkgsFound;
	unless ($findParams) {
		return @pkgsFound;
	}
	unless ($findParams->{NEEDLE}) {
		return @pkgsFound;
	}
	unless ($findParams->{IDSLACKVER}) {
		return @pkgsFound;
	}
	unless ($findParams->{IDSLACKVER} =~ /^[0-9]+$/) {
		return @pkgsFound;
	}
	unless ($findParams->{SLACKVERNAME}) {
		return @pkgsFound;
	}
	unless ($findParams->{SLACKVERNAME} =~ /^[A-Za-z0-9\.\-]+$/) {
		return @pkgsFound;
	}
	unless ($catsToCheck) {
		return @pkgsFound;
	}	
	
	my $sqlitePath = $self->cfg('SQLITE_PATH');
	my $sqLiteFile = $sqlitePath."/".$findParams->{SLACKVERNAME}.".sq3";
	unless ( -e $sqLiteFile ) {
		return @pkgsFound;
	}

	my $dbhLite = DBI->connect("dbi:SQLite:dbname=".$sqLiteFile, 
		"","", 
		{ AutoCommit => 1,
      PrintError => 0,
			RaiseError => 0
		}
	);
	unless ($dbhLite) {
		return @pkgsFound;
	}

	my $dbh = $self->dbh;

	my $sql1 = sprintf("SELECT id_packages FROM files WHERE \
	file_name LIKE '%%%s%%' GROUP BY id_packages;", $findParams->{NEEDLE});
	my $result1 = $dbhLite->selectall_arrayref($sql1, { Slice => {}});
	
	my @idPkgs;
	for my $row1 (@$result1) {
		push(@idPkgs, $row1->{id_packages});
	}
	
	if (@idPkgs == 0) {
		$dbhLite->disconnect;
		return @pkgsFound;
	}

	my $sqlCats = "";
	unless (@$catsToCheck == 0) {
		$sqlCats = sprintf(" AND view_packages.id_category IN (%s)", 
			join(",", @$catsToCheck));
	}

	my $idPkgsSQL = join(", ", @idPkgs);
	my $sql2 = "SELECT id_packages, package_name, package_size, \
	package_created, category.category_name, serie.serie_name \
 	FROM view_packages FULL JOIN category ON \
	category.id_category = view_packages.id_category \
	FULL JOIN serie ON serie.id_serie = view_packages.id_serie \
	WHERE id_slackversion = ".$findParams->{IDSLACKVER}." AND \
	id_packages IN (".$idPkgsSQL.")".$sqlCats
	." ORDER BY package_name;";

	my $result2 = $dbh->selectall_arrayref($sql2, { Slice => {} });
	
	if (@$result2 == 0) {
		return @pkgsFound;
	}

	my $scriptPath = substr($ENV{SCRIPT_NAME}, 0, 
		rindex($ENV{SCRIPT_NAME}, "/")+1);

	my %packagesFiltered;
	for my $row2 (@$result2) {
		my $serieEnc = $row2->{serie_name};
		$serieEnc =~ s/\/+/@/g;
		$serieEnc =~ $self->_url_encode($serieEnc);
		my $pkgLocation = sprintf("%s/%s", $row2->{category_name},
			$row2->{serie_name});
		$pkgLocation =~ s/\/\//\//so;
		my $pkgNameURL = $row2->{package_name};
		$pkgNameURL =~ s/\.t(g|x)z//;
		my $pkgURLPath = sprintf("%spackage.cgi/view/%s/%s/%s/%s", $scriptPath, 
			$findParams->{SLACKVERNAME}, $row2->{category_name}, $serieEnc, 
			$pkgNameURL);
		$pkgURLPath =~  s/\/\//\//so;
		my $pkgSize = sprintf("%.0f kB", $row2->{package_size}/1000);
		my %item = ( PKGNAME => $row2->{package_name},
			PKGSIZE => $pkgSize,
			PKGDATE => $row2->{package_created},
			PKGTEXT => "",
			PKGFILES => 0,
			PKGLOCATION => $pkgLocation,
			PKGURL => $pkgURLPath,
		);
		my $key2 = $row2->{id_packages};
		$packagesFiltered{$key2} = \%item;
	} # for my $row2
	
	my $idPkgsFilt = join(", ", keys(%packagesFiltered));
	my $sql3 = sprintf("SELECT id_packages, file_name FROM files WHERE \
	file_name LIKE '%%%s%%' AND id_packages IN (%s));", 
	$findParams->{NEEDLE}, $idPkgsFilt);
	my $result3 = $dbhLite->selectall_arrayref($sql3, { Slice => {}});

	for my $row3 (@$result3) {
		my $key3 = $row3->{id_packages};
		unless ($packagesFiltered{$key3}) {
			next;
		}
		my $entry = $packagesFiltered{$key3};
		$entry->{PKGFILES}++;
		if ($entry->{PKGFILES} > LIMITFILES) {
			next;
		}
		$entry->{PKGTEXT}.= $row3->{file_name}."\n";
	} # for my $row3

	@pkgsFound = values(%packagesFiltered);

	$dbhLite->disconnect;
	return @pkgsFound;
} # sub _find_files
# desc: find packages matching $needle in PgSQL
# $needle: string;
# $idSlackver: int;
# $catsToCheck: array ref;
# @return: array;
sub _find_packages {
	my $self = shift;
	my $findParams = shift;
#	my $needle = shift;
#	my $idSlackver = shift;
	my $catsToCheck = shift;
	my @pkgsFound;
	unless ($findParams) {
		return @pkgsFound;
	}
	unless ($findParams->{NEEDLE}) {
		return @pkgsFound;
	}
	unless ($findParams->{IDSLACKVER}) {
		return @pkgsFound;
	}
	unless ($findParams->{SLACKVERNAME}) {
		return @pkgsFound;
	}
	if ($findParams->{IDSLACKVER} !~ /^[0-9]+$/) {
		return @pkgsFound;
	}
	unless ($catsToCheck) {
		return @pkgsFound;
	}

	my $dbh = $self->dbh;
	
	my $sqlCats = "";
	unless (@$catsToCheck == 0) {
		$sqlCats = sprintf(" AND view_packages.id_category IN (%s)", 
			join(",", @$catsToCheck));
	}

	my $sql1 = "SELECT \
	id_packages, 
	package_name, \
	package_size, \
	package_created, \
	package_desc, \
	category.category_name, \
	serie.serie_name \
 	FROM view_packages 
	FULL JOIN category ON category.id_category = view_packages.id_category \
	FULL JOIN serie ON serie.id_serie = view_packages.id_serie \
	WHERE id_slackversion = ".$findParams->{IDSLACKVER}." AND \
	package_name LIKE '%".$findParams->{NEEDLE}."%'".$sqlCats
	." ORDER BY package_name;";

	my $result1 = $dbh->selectall_arrayref($sql1, { Slice => {} });

	my $scriptPath = substr($ENV{SCRIPT_NAME}, 0, 
		rindex($ENV{SCRIPT_NAME}, "/")+1);

	for my $row (@$result1) {
		my $serieEnc = $row->{serie_name};
		$serieEnc =~ s/\/+/@/g;
		$serieEnc =~ $self->_url_encode($serieEnc);
		my $pkgLocation = sprintf("%s/%s", $row->{category_name},
			$row->{serie_name});
		$pkgLocation =~ s/\/\//\//so;
		my $pkgNameURL = $row->{package_name};
		$pkgNameURL =~ s/\.t(g|x)z//;
		my $pkgURLPath = sprintf("%spackage.cgi/view/%s/%s/%s/%s", $scriptPath, 
			$findParams->{SLACKVERNAME}, $row->{category_name}, $serieEnc, 
			$pkgNameURL);
		$pkgURLPath =~  s/\/\//\//so;
		my %item = ( PKGNAME => $row->{package_name},
#			PKGSIZE => $row->{package_size},
			PKGDATE => $row->{package_created},
			PKGTEXT => $row->{package_desc},
			PKGLOCATION => $pkgLocation,
			PKGURL => $pkgURLPath,
		);
		push(@pkgsFound, \%item);
	}

	return @pkgsFound;
} # sub _find_packages

1;

