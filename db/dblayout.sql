----------------------------------
-- DB layout proposal for
-- slackverse.org
-- pkg search & index
--
-- v2
-- 
-- 2010/Feb/XX @ Zdenek Styblik
--
----------------------------------
-- serial	4 bytes	autoincrementing integer	1 to 2147483647
-- bigserial	8 bytes	large autoincrementing integer	1 to 9223372036854775807
--
CREATE TABLE datafile (
	id_datafile SERIAL NOT NULL UNIQUE,
	id_slackversion INTEGER NOT NULL,
	fpath VARCHAR NOT NULL,
	dfile_md5sum CHAR(32) DEFAULT NULL,
	dfile_created TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX datafile_key1 ON datafile (id_slackversion, fpath);

-- category
CREATE TABLE category (
	id_category SERIAL NOT NULL PRIMARY KEY UNIQUE, 
	category_name VARCHAR NOT NULL UNIQUE
);
CREATE OR REPLACE RULE "ctgry_insert_ignore" AS ON INSERT TO category WHERE EXISTS(SELECT true FROM category WHERE category_name = NEW.category_name) DO INSTEAD NOTHING;

CREATE TABLE country (
	id_country SERIAL NOT NULL PRIMARY KEY UNIQUE,
	name VARCHAR NOT NULL,
	name_short CHAR(2),
	flag_url TEXT NOT NULL DEFAULT '/img/flag-icons/png/none.png'
);

CREATE TABLE mirror (
	id_mirror SERIAL NOT NULL PRIMARY KEY UNIQUE,
	mirror_url VARCHAR NOT NULL UNIQUE,
	id_country INTEGER REFERENCES country(id_country),
	mirror_updated TIMESTAMP NOT NULL DEFAULT NOW(),
	mirror_desc VARCHAR NOT NULL,
	mirror_proto VARCHAR(5) NOT NULL
);
CREATE OR REPLACE RULE "mirror_insert_update" AS ON INSERT TO mirror WHERE EXISTS(SELECT true FROM mirror WHERE mirror_url = NEW.mirror_url) DO INSTEAD UPDATE mirror SET mirror_updated = NOW() WHERE mirror_url = NEW.mirror_url;

-- package
CREATE TABLE package (
	id_package SERIAL NOT NULL PRIMARY KEY UNIQUE, 
	package_name VARCHAR NOT NULL UNIQUE
);
CREATE OR REPLACE RULE "package_insert_ignore" AS ON INSERT TO package WHERE EXISTS(SELECT true FROM package WHERE package_name = NEW.package_name) DO INSTEAD NOTHING;

-- serie
CREATE TABLE serie (
	id_serie SERIAL NOT NULL PRIMARY KEY UNIQUE, 
	serie_name VARCHAR NOT NULL UNIQUE
);
CREATE OR REPLACE RULE "serie_insert_ignore" AS ON INSERT TO serie WHERE EXISTS(SELECT true FROM serie WHERE serie_name = NEW.serie_name) DO INSTEAD NOTHING;

-- slackversion
CREATE TABLE slackversion (
	id_slackversion SERIAL NOT NULL PRIMARY KEY UNIQUE, 
	slackversion_name VARCHAR(32) NOT NULL UNIQUE,
	version FLOAT NOT NULL DEFAULT 0,
	ts_last_update TIMESTAMP NOT NULL DEFAULT NOW(),
	no_files INTEGER NOT NULL DEFAULT 0,
	no_pkgs INTEGER NOT NULL DEFAULT 0
);

-- packages
CREATE TABLE packages (
	id_packages SERIAL NOT NULL PRIMARY KEY UNIQUE, 
	id_serie INTEGER DEFAULT NULL REFERENCES serie(id_serie),
	id_category INTEGER NOT NULL REFERENCES category(id_category),
	id_slackversion INTEGER NOT NULL REFERENCES slackversion(id_slackversion),
	id_package INTEGER NOT NULL REFERENCES package(id_package) ON DELETE RESTRICT,
	package_size INTEGER DEFAULT 0 NOT NULL,
	package_created TIMESTAMP NOT NULL,
	package_md5sum CHAR(32) DEFAULT NULL,
	package_desc TEXT DEFAULT NULL,
	package_contents TEXT DEFAULT NULL
);
CREATE UNIQUE INDEX packages_index1 ON packages (id_slackversion, 
	id_category, id_serie, id_package);

CREATE VIEW view_packages AS SELECT packages.id_packages, 
packages.id_serie, 
packages.id_category, 
packages.id_slackversion, 
packages.id_package, 
packages.package_size, 
packages.package_created, 
packages.package_md5sum, 
packages.package_desc, 
package.package_name 
FROM packages JOIN package ON 
packages.id_package = package.id_package;

