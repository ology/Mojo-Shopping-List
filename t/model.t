#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use lib map { "$ENV{HOME}/sandbox/$_/lib" } qw(Test-SQLite);
use Test::SQLite;

use ShoppingList::Model;
use Schema;

# Setup the test database
my $sqlite = Test::SQLite->new;
my $schema = Schema->connect($sqlite->dsn);
isa_ok $schema, 'Schema';
$schema->deploy;

# Get a new model object
my $model = new_ok 'ShoppingList::Model' => [schema => $schema];

# Create a new account
my $account = $model->new_user('test@example.com', 'test', 'test');
isa_ok $account, 'Schema::Result::Account';

# Test that authorization fails
ok !$model->auth($account->username, 'foo'), 'auth';

# Test that authorization works
ok $model->auth($account->username, 'test'), 'auth';

# Test that an account can be found
my $got = $model->find_account($account->id);
is $got->id, $account->id, 'find_account';

# Test that an account can be searched for
$got = $model->search_username($account->username);
is $got->id, $account->id, 'search_username';

# Create a new list for the account
my $list = $model->new_list($account->id, 'Test list');
isa_ok $list, 'Schema::Result::List';

# Test that a bogus account doesn't own the list
$got = $model->list_owner(0, $list->id);
ok !$got, 'list_owner';

# Test that the account doesn't own a bogus list
$got = $model->list_owner($account->id, 0);
ok !$got, 'list_owner';

# Test that the account owns the list
$got = $model->list_owner($account->id, $list->id);
is $got->id, $list->id, 'list_owner';

# Test that the list is in the account lists
$got = $model->lists($account->id);
while (my $i = $got->next) {
    is $i->id, $list->id, 'lists';
}

# Test that the list is in the account lists
$got = $model->account_lists($account->id);
while (my $i = $got->next) {
    is $i->id, $list->id, 'account_lists';
}

# Test that the list is in the account lists
$got = $model->lists_by_account($account);
while (my $i = $got->next) {
    is $i->id, $list->id, 'lists_by_account';
}

# Test that the list can be found by id
$got = $model->find_list($list->id);
is $got->id, $list->id, 'find_list';

# Test that the list name can be updated
$got = $model->update_list($account->id, $list->id, 'Test list!');
is $got->name, 'Test list!', 'update_list';

# Create a new item for the account
my $item = $model->new_item(
    account_id => $account->id,
    name       => 'Test item',
    category   => 'Testing',
    quantity   => 1,
);
isa_ok $item, 'Schema::Result::Item';

# Test that the item can be found by id
$got = $model->find_item($account->id, $item->id);
is $got->id, $item->id, 'find_item';

# Test that the item can be queried for
my $all_items = $account->items;
$got = $model->query_items($all_items, '%');
while (my $i = $got->next) {
    is $i->id, $item->id, 'query_items';
}

# Test that the categories can be returned
$got = $model->categories($all_items);
while (my $i = $got->next) {
    is $i->category, 'Testing', 'categories';
}

# Test that items not on the list can be returned
$got = $model->off_items($account->id, {});
while (my $i = $got->next) {
    is $i->id, $item->id, 'off_items';
}

# Test that the item is not on the list
$got = $model->ordered_items($list, {});
ok !$got->count, 'ordered_items';

# Add the item to the list
$got = $model->update_item_list($account->id, $item->id, $list->id);
is $got->list_id, $list->id, 'update_item_list';

# Test that the item is on the list
$got = $model->list_items($account->id);
while (my $i = $got->next) {
    is $i->id, $item->id, 'list_items';
}

# Test that the item is on the list
$got = $model->ordered_items($list, {});
while (my $i = $got->next) {
    is $i->id, $item->id, 'ordered_items';
}

# Test that the item count has not been updated
$got = $schema->resultset('ItemCount');
ok !$got->count, 'counts';

# Test that there is nothing to suggest
$got = $model->suggestion($account->id, []);
ok !$got, 'suggestion';

# Move the item to the list (and update the count)
$got = $model->move_item($account->id, $item->id, $list->id);
is $got->list_id, $list->id, 'move_item';

# Test that the item count has been updated
$got = $schema->resultset('ItemCount');
is $got->count, 1, 'counts';

# Test that the item count can be updated again
$model->update_or_create($account->id, $item->id);
$got = $schema->resultset('ItemCount');
while (my $i = $got->next) {
    is $i->count, 2, 'update_or_create';
}

# Remove the item from the list
$got = $model->update_item_list($account->id, $item->id, undef);
is $got->list_id, undef, 'update_item_list';

# Test that the item is suggested
$got = $model->suggestion($account->id, []);
is $got->id, $item->id, 'suggestion';

# Put the item back on the list
$got = $model->update_item_list($account->id, $item->id, $list->id);
is $got->list_id, $list->id, 'update_item_list';

# Test that the list can be deleted
$model->delete_list($account->id, $list->id);
$got = $model->lists($account->id);
ok !$got->count, 'delete_list';

# Test that the item can be queried for still
$all_items = $account->items;
$got = $model->query_items($all_items, '%');
while (my $i = $got->next) {
    is $i->id, $item->id, 'query_items';
}

# Test that the item can be deleted
$model->delete_item($account->id, $item->id);
$all_items = $account->items;
ok !$all_items->count, 'delete_item';

# Test that the item count has been removed
$got = $schema->resultset('ItemCount');
ok !$got->count, 'counts';

done_testing();
