#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use Schema;

my ($name, $pass) = @ARGV;

my $db_file = 'shopping_list.db';

unlink $db_file
    if -e $db_file;
unlink $db_file . '.journal'
    if -e $db_file . '.journal';

my $schema = Schema->connect('DBI:SQLite:dbname=' . $db_file, '', '');

$schema->deploy({ add_drop_table => 1 });

if ($name && $pass) {
    $schema->resultset('Account')->create({ username => $name, password => $pass });
}
