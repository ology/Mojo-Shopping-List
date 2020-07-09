#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use Schema;

my ($name, $pass) = @ARGV;

my $config = do './shopping_list.conf';

my $schema = Schema->connect($config->{database}, '', '');

my $account = $schema->resultset('Account')->search({ username => $name })->single;

if ($account) {
    $account->update({ password => $pass });
}
else {
    $schema->resultset('Account')->create({ username => $name, password => $pass });
}
