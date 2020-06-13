#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use Schema;

my ($name, $pass) = @ARGV;

my $config = do 'shopping_list.conf';

(my $db_file = $config->{database}) =~ s/^.*?=(.*)$/$1/;

unlink $db_file
    if -e $db_file;
unlink $db_file . '.journal'
    if -e $db_file . '.journal';

my $schema = Schema->connect($config->{database}, '', '');

$schema->deploy({ add_drop_table => 1 });

if ($name && $pass) {
    $schema->resultset('Account')->create({ username => $name, password => $pass });
}
