package ShoppingList::Model;

use strict;
use warnings;

sub new { bless {}, shift }

sub auth {
    my ($self, $schema, $user, $pass) = @_;
    my $result = $schema->resultset('Account')->search({ username => $user })->first;
    return $result
        if $result && $result->check_password($pass);
}

sub lists {
    my ($self, $schema, $account) = @_;
    my $result = $schema->resultset('Account')->find($account);
    my $lists = $result->lists->search({}, { order_by => { -asc => \'LOWER(name)' } });
    return $lists;
}

sub list_owner {
    my ($self, $schema, $account, $list) = @_;
    my $result = $account ? $schema->resultset('Account')->find($account) : undef;
    return $result ? $result->lists->find($list) : 0;
}

sub new_list {
    my ($self, $schema, $account, $name) = @_;
    my $result = $schema->resultset('List')->create({
        name       => $name,
        account_id => $account,
    });
    return $result;
}

sub update_list {
    my ($self, $schema, $list, $name) = @_;
    my $result = $schema->resultset('List')->find($list);
    $result->update({ name => $name });
    return $result;
}

sub delete_list {
    my ($self, $schema, $list) = @_;
    my $result = $schema->resultset('List')->find($list);
    my $items = $result->items;
    while (my $item = $items->next) {
        $item->update({ list_id => undef });
    }
    $result->delete;
}

sub find_list {
    my ($self, $schema, $list) = @_;
    my $result = $schema->resultset('List')->find($list);
    return $result;
}

sub ordered_items {
    my ($self, $result, $order) = @_;
    my $items = $result->items->search({}, { %$order });
    return $items;
}

sub off_items {
    my ($self, $schema, $account, $order) = @_;
    my $items = $schema->resultset('Item')->search(
        {
            account_id => $account,
            list_id    => undef,
        },
        {
            %$order,
        }
    );
    return $items;
}

sub categories {
    my ($self, $items) = @_;
    my $categories = $items->search(
        {},
        {
            distinct => 1,
            columns  => [qw/category/],
            order_by => { -asc => \'LOWER(category)' },
        }
    );
    return $categories;
}

sub account_lists {
    my ($self, $schema, $account) = @_;
    my $lists = $schema->resultset('List')->search(
        {
            account_id => $account,
        },
        {
            order_by => { -asc => \'LOWER(name)' },
        }
    );
    return $lists;
}

sub list_items {
    my ($self, $schema, $account) = @_;
    my $list_items = $schema->resultset('Item')->search(
        {
            account_id => $account,
            list_id    => { '!=' => undef },
        }
    );
    return $list_items;
}

sub suggestion {
    my ($self, $schema, $account, $exclude) = @_;
    my $result = $schema->resultset('ItemCount')->search(
        {
            account_id => $account,
            item_id    => { -not_in => $exclude },
        },
        {
            order_by => { -desc => 'count' },
        }
    )->first;
    return $result;
}

sub find_item {
    my ($self, $schema, $item) = @_;
    my $result = $schema->resultset('Item')->find($item);
    return $result;
}

sub update_or_create {
    my ($self, $schema, $account, $id) = @_;
    $schema->resultset('ItemCount')->update_or_create($account, $id);
}

sub update_item_list {
    my ($self, $schema, $item, $list) = @_;
    my $result = $schema->resultset('Item')->find($item);
    $result->update({ list_id => $list });
    return $result;
}

sub delete_item {
    my ($self, $schema, $item) = @_;
    my $result = $self->rs('Item')->find($item);
    $result->delete;
    $result = $self->rs('ItemCount')->search({ item_id => $item })->first;
    $result->delete if $result;
}

sub move_item {
    my ($self, $schema, $account, $item, $list) = @_;
    my $result = $self->rs('Item')->find($item);
    $result->update({ list_id => $list });
    $self->rs('ItemCount')->update_or_create($account, $item);
}

sub find_account {
    my ($self, $schema, $account) = @_;
    my $result = $schema->resultset('Account')->find($account);
    return $result;
}

sub lists_by_account {
    my ($self, $account) = @_;
    my $lists = $account->lists->search(
        {},
        {
            order_by => { -asc => \'LOWER(name)' },
        }
    );
}

sub query_items {
    my ($self, $all_items, $query) = @_;
    my $list_items = $all_items->search(
        {
            -or => [
                name     => { like => $query },
                note     => { like => $query },
                category => { like => $query },
            ],
        },
        {
            order_by => { -asc => \'LOWER(name)' },
        }
    );
    return $list_items;
}

sub new_item {
    my $self = shift;
    my %args = @_;
    my $item = $args{schema}->resultset('Item')->create({
        account_id => $args{account_id},
        name       => $args{name},
        note       => $args{note},
        category   => $args{category},
        cost       => $args{cost},
        quantity   => $args{quantity} || 1,
        list_id    => $args{list_id},
    });
    return $item;
}

sub new_user {
    my ($self, $schema, $email, $user, $pass) = @_;
    $$schema->resultset('Account')->create({
        email    => $email,
        username => $user,
        password => $pass,
    });
}

1;
