package Slackware::Search::FinderCLI;
use base 'CGI::Application';

use strict;
use warnings;

use CGI::Application::Plugin::ConfigAuto	(qw/cfg/);
use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use CGI::Application::Plugin::Routes;
use constant NEEDLEMINLENGTH => 2;

sub setup {
	my $self = shift;
	$self->start_mode('noparam');

	$self->header_props(-type => 'text/plain', -charset => 'UTF-8');
	# routes_root optionally is used to prepend a URI part to 
	# every route
	$self->routes_root('/'); 
	$self->routes([
		'' => 'noparam' ,
		'/find/:haystack/:slackversion/:needle' => 'find',
	]);
} # sub setup

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

sub noparam {
	return "No parameters or wrong run mode.\n";
}

sub find {
	my $self = shift;
	my $q = $self->query();
	my $haystack = $q->param('haystack') || undef;
	my $slackVer = $q->param('slackversion') || undef;
	my $needle = $q->param('needle') || undef;

	unless ($haystack) {
		return "Haystack is undefined.\n";
	}
	unless ($slackVer) {
		return "Slackware version is undefined.\n";
	}
	unless ($needle) {
		return "Needle is undefined.\n";
	}
	unless ($haystack eq 'file' || $haystack eq 'package') {
		return "Supported haystacks are 'file' and 'package'.\n";
	}
	if (length($slackVer) < NEEDLEMINLENGTH 
		|| length($needle) < NEEDLEMINLENGTH) {
		return "Slackware version or needle are too short.\n";
	}
	$slackVer = lc($slackVer);
	unless ($slackVer 
		=~ /^slackware(64)?-(current|[0-9]+\.[0-9]+){1}$/) {
		return "Invalid slackware version name.\n";
	}
	unless ($needle =~ /^[A-Za-z0-9\.\-\_]+$/) {
		return "Invalid characters in needle.\n";
	}

	my $idSlackVer = $self->_get_slackversion_id($slackVer);
	unless ($idSlackVer) {
		return "Slackware version '$slackVer' not found in DB.\n";
	}
	
	my @pkgsFound;
	if ($haystack eq 'file') {
		@pkgsFound = $self->_find_files($needle, $idSlackVer, $slackVer);
	} else {
		@pkgsFound = $self->_find_packages($needle, $idSlackVer);
	}
	
	return "Nothing found.\n" if (@pkgsFound == 0);

	my $output;	
	for my $item (@pkgsFound) {
		$output.= sprintf("%s|%s\n", $item->{PKGNAME}, 
			$item->{PKGLOCATION});
	}
	return $output;
} # sub find
# desc: return id_slackversion;
# $slackVer: string;
# @return: int;
sub _get_slackversion_id {
	my $self = shift;
	my $slackVer = shift;

	my $dbh = $self->dbh;
	return undef unless ($dbh);

	my $sql1 = "SELECT id_slackversion FROM slackversion WHERE 
	slackversion_name = '$slackVer' LIMIT 1;";
	my $idSlackVer = $dbh->selectrow_array($sql1) 
		or die("Unable to select Slackware version ID.");
	return undef unless ($idSlackVer);
	return $idSlackVer;
} # sub _get_slackware_id
# desc: find packages->files matching $needle in SQLite
# $needle: string;
# $slackver: string;
# @return: array;
sub _find_files {
	my $self = shift;
	my $needle = shift;
	my $idSlackver = shift;
	my $slackver = shift;
	my @pkgsFound;
	unless ($needle) {
		return @pkgsFound;
	}
	unless ($idSlackver) {
		return @pkgsFound;
	}
	unless ($idSlackver =~ /^[0-9]+$/) {
		return @pkgsFound;
	}
	unless ($slackver) {
		return @pkgsFound;
	}
	unless ($slackver =~ /^[A-Za-z0-9\.\-]+$/) {
		return @pkgsFound;
	}
	
	my $sqlitePath = $self->cfg('SQLITE_PATH');
	my $sqLiteFile = $sqlitePath."/".$slackver.".sq3";
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

	my $sql1 = "SELECT id_packages FROM files WHERE \
	file_name LIKE '%".$needle."%' GROUP BY id_packages;";
	my $result1 = $dbhLite->selectall_arrayref($sql1, { Slice => {}});

	$dbhLite->disconnect;
	
	my @idPkgs;
	for my $row1 (@$result1) {
		push(@idPkgs, $row1->{id_packages});
	}
	
	if (@idPkgs == 0) {
		$dbhLite->disconnect;
		return @pkgsFound;
	}

	my $idPkgsSQL = join(", ", @idPkgs);
	my $sql2 = "SELECT id_packages, package_name, 
	category.category_name, serie.serie_name \
 	FROM view_packages FULL JOIN category ON \
	category.id_category = view_packages.id_category \
	FULL JOIN serie ON serie.id_serie = view_packages.id_serie \
	WHERE id_slackversion = ".$idSlackver." AND \
	id_packages IN (".$idPkgsSQL.") ORDER BY package_name;";

	my $result2 = $dbh->selectall_arrayref($sql2, { Slice => {} });
	
	if (@$result2 == 0) {
		return @pkgsFound;
	}

	my %packagesFiltered;
	for my $row2 (@$result2) {
		my $pkgLocation = $row2->{category_name}."/"
		.$row2->{serie_name};
		$pkgLocation =~ s/\/\//\//so;
		my %item = ( PKGNAME => $row2->{package_name},
			PKGLOCATION => $pkgLocation,
		);
		my $key2 = $row2->{id_packages};
		$packagesFiltered{$key2} = \%item;
	} # for my $row2

	@pkgsFound = values(%packagesFiltered);

	return @pkgsFound;
} # sub _find_files
# desc: find packages matching $needle in PgSQL
# $needle: string;
# $idSlackver: int;
# $catsToCheck: array ref;
# @return: array;
sub _find_packages {
	my $self = shift;
	my $needle = shift;
	my $idSlackver = shift;
	my @pkgsFound;
	unless ($needle) {
		return @pkgsFound;
	}
	unless ($idSlackver) {
		return @pkgsFound;
	}
	if ($idSlackver !~ /^[0-9]+$/) {
		return @pkgsFound;
	}

	my $dbh = $self->dbh;

	my $sql1 = "SELECT package_name, category.category_name, \
	serie.serie_name \
 	FROM view_packages FULL JOIN category ON \
	category.id_category = view_packages.id_category \
	FULL JOIN serie ON serie.id_serie = view_packages.id_serie \
	WHERE id_slackversion = ".$idSlackver." AND \
	package_name LIKE '%".$needle."%' ORDER BY package_name;";

	my $result1 = $dbh->selectall_arrayref($sql1, { Slice => {} });

	for my $row (@$result1) {
		my $pkgLocation = $row->{category_name}."/"
		.$row->{serie_name};
		$pkgLocation =~ s/\/\//\//so;
		my %item = ( PKGNAME => $row->{package_name},
			PKGLOCATION => $pkgLocation,
		);
		push(@pkgsFound, \%item);
	}

	return @pkgsFound;
} # sub _find_packages

1;
