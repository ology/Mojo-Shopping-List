#!/usr/bin/env perl
use strict;
use warnings;

__END__
use DBI;

use lib 'lib';
use Schema;

my $dbh = DBI->connect('DBI:SQLite:dbname=../ShopList/shoplist.db', '', '') or die $DBI::errstr;

my $config = do './shopping_list.conf';

my $schema = Schema->connect($config->{database}, '', '');

my $sql = 'SELECT * FROM shop_list where account_id=2';
my $sth = $dbh->prepare($sql) or die $dbh->errstr;
$sth->execute() or die $dbh->errstr;
my $data = $sth->fetchall_hashref('id');
for my $datum (keys %$data) {
    $schema->resultset('List')->create({
        account_id => $data->{$datum}{account_id},
        name       => $data->{$datum}{name},
    });
}

$sql = 'SELECT * FROM item where account_id=2';
$sth = $dbh->prepare($sql) or die $dbh->errstr;
$sth->execute() or die $dbh->errstr;
$data = $sth->fetchall_hashref('id');
for my $datum (keys %$data) {
    $schema->resultset('Item')->create({
        account_id => $data->{$datum}{account_id},
        name       => $data->{$datum}{name},
        category   => $data->{$datum}{category},
        note       => $data->{$datum}{note},
        cost       => $data->{$datum}{cost},
    });
}
