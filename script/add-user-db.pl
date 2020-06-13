#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use Schema;

my ($name, $pass) = @ARGV;

my $config = do 'shopping_list.conf';

my $schema = Schema->connect($config->{database}, '', '');

$schema->resultset('Account')->create({ username => $name, password => $pass });
