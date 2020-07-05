#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use lib $ENV{HOME} . '/sandbox/Test-SQLite/lib';
use Test::SQLite;

use ShoppingList::Model;
use Schema;

my $sqlite = Test::SQLite->new;
my $schema = Schema->connect($sqlite->dsn);
isa_ok $schema, 'Schema';
$schema->deploy;

my $model = new_ok 'ShoppingList::Model' => [schema => $schema];

my $account = $model->new_user('test@example.com', 'test', 'test');
isa_ok $account, 'Schema::Result::Account';

ok $model->auth($account->username, 'test'), 'auth';

my $got = $model->find_account($account->id);
is $got->id, $account->id, 'find_account';

$got = $model->search_username($account->username);
is $got->id, $account->id, 'search_username';

my $list = $model->new_list($account->id, 'Test list');
isa_ok $list, 'Schema::Result::List';

$got = $model->list_owner(0, $list->id);
ok !$got, 'list_owner';

$got = $model->list_owner($account->id, 0);
ok !$got, 'list_owner';

$got = $model->list_owner($account->id, $list->id);
is $got->id, $list->id, 'list_owner';

$got = $model->lists($account->id);
while (my $i = $got->next) {
    is $i->id, $list->id, 'lists';
}

$got = $model->account_lists($account->id);
while (my $i = $got->next) {
    is $i->id, $list->id, 'account_lists';
}

$got = $model->lists_by_account($account);
while (my $i = $got->next) {
    is $i->id, $list->id, 'lists_by_account';
}

$got = $model->find_list($list->id);
is $got->id, $list->id, 'find_list';

$got = $model->update_list($list->id, 'Test list!');
is $got->name, 'Test list!', 'update_list';

my $item = $model->new_item(
    account_id => $account->id,
    name       => 'Test item',
    category   => 'Testing',
    quantity   => 1,
);
isa_ok $item, 'Schema::Result::Item';

$got = $model->find_item($item->id);
is $got->id, $item->id, 'find_item';

my $all_items = $account->items;
$got = $model->query_items($all_items, '%');
while (my $i = $got->next) {
    is $i->id, $item->id, 'query_items';
}

$got = $model->categories($all_items);
while (my $i = $got->next) {
    is $i->category, 'Testing', 'categories';
}

$got = $model->off_items($account->id, {});
while (my $i = $got->next) {
    is $i->id, $item->id, 'off_items';
}

$got = $model->ordered_items($list, {});
ok !$got->count, 'ordered_items';

$got = $model->update_item_list($item->id, $list->id);
is $got->list_id, $list->id, 'update_item_list';

$got = $model->list_items($account->id);
while (my $i = $got->next) {
    is $i->id, $item->id, 'list_items';
}

$got = $model->ordered_items($list, {});
while (my $i = $got->next) {
    is $i->id, $item->id, 'ordered_items';
}

$got = $schema->resultset('ItemCount');
ok !$got->count, 'counts';

$got = $model->suggestion($account->id, []);
ok !$got, 'suggestion';

$got = $model->move_item($account->id, $item->id, $list->id);
is $got->list_id, $list->id, 'move_item';

$got = $schema->resultset('ItemCount');
is $got->count, 1, 'counts';

$model->update_or_create($account->id, $item->id);
$got = $schema->resultset('ItemCount');
while (my $i = $got->next) {
    is $i->count, 2, 'update_or_create';
}

$got = $model->update_item_list($item->id, undef);
is $got->list_id, undef, 'update_item_list';

$got = $model->suggestion($account->id, []);
is $got->id, $item->id, 'suggestion';

$got = $model->update_item_list($item->id, $list->id);
is $got->list_id, $list->id, 'update_item_list';

$model->delete_list($list->id);
$got = $model->lists($account->id);
ok !$got->count, 'delete_list';

$all_items = $account->items;
$got = $model->query_items($all_items, '%');
while (my $i = $got->next) {
    is $i->id, $item->id, 'query_items';
}

$model->delete_item($item->id);
$all_items = $account->items;
ok !$all_items->count, 'delete_item';

$got = $schema->resultset('ItemCount');
ok !$got->count, 'counts';

done_testing();
