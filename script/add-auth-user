#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use Schema;

my ($name, $pass) = @ARGV;

my $schema = Schema->connect('DBI:SQLite:dbname=shopping_list.db', '', '');

$schema->resultset('Account')->create({ username => $name, password => $pass });
