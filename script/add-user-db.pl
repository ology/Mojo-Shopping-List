#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use Schema;

my $config = do 'shopping_list.conf';

my ($name, $pass) = @ARGV;

my $schema = Schema->connect($config->{database}, '', '');

$schema->resultset('Account')->create({ username => $name, password => $pass });
