package ShoppingList::Model;

use Mojo::Base -base;

has 'schema';

sub auth {
    my ($self, $user, $pass) = @_;
    my $result = $self->schema->resultset('Account')->search({ username => $user })->first;
    return $result
        if $result && $result->check_password($pass);
}

sub lists {
    my ($self, $account) = @_;
    my $result = $self->schema->resultset('Account')->search({ id => $account })->first;
    return unless $result;
    my $lists = $result->lists->search({}, { order_by => { -asc => \'LOWER(name)' } });
    return $lists;
}

sub list_owner {
    my ($self, $account, $list) = @_;
    my $result = $self->schema->resultset('Account')->search({ id => $account })->first;
    return unless $result;
    return $result ? $result->lists->find($list) : 0;
}

sub item_owner {
    my ($self, $account, $item) = @_;
    my $result = $self->schema->resultset('Account')->search({ id => $account })->first;
    return unless $result;
    return $result ? $result->items->find($item) : 0;
}

sub new_list {
    my ($self, $account, $name) = @_;
    my $result = $self->schema->resultset('List')->create({
        name       => $name,
        account_id => $account,
    });
    return $result;
}

sub update_list {
    my ($self, $list, $name) = @_;
    my $result = $self->schema->resultset('List')->search({ id => $list })->first;
    return unless $result;
    $result->update({ name => $name });
    return $result;
}

sub delete_list {
    my ($self, $list) = @_;
    my $result = $self->schema->resultset('List')->search({ id => $list })->first;
    return unless $result;
    my $items = $result->items;
    while (my $item = $items->next) {
        $item->update({ list_id => undef });
    }
    $result->delete;
}

sub find_list {
    my ($self, $list) = @_;
    my $result = $self->schema->resultset('List')->search({ id => $list })->first;
    return $result;
}

sub ordered_items {
    my ($self, $list, $order) = @_;
    my $items = $list->items->search({}, { %$order });
    return $items;
}

sub off_items {
    my ($self, $account, $order) = @_;
    my $items = $self->schema->resultset('Item')->search(
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
    my ($self, $account) = @_;
    my $lists = $self->schema->resultset('List')->search(
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
    my ($self, $account) = @_;
    my $list_items = $self->schema->resultset('Item')->search(
        {
            account_id => $account,
            list_id    => { '!=' => undef },
        }
    );
    return $list_items;
}

sub suggestion {
    my ($self, $account, $exclude) = @_;
    my $result = $self->schema->resultset('ItemCount')->search(
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
    my ($self, $item) = @_;
    my $result = $self->schema->resultset('Item')->search({ id => $item })->first;
    return $result;
}

sub update_or_create {
    my ($self, $account, $id) = @_;
    $self->schema->resultset('ItemCount')->update_or_create($account, $id);
}

sub update_item_list {
    my ($self, $item, $list) = @_;
    my $result = $self->schema->resultset('Item')->search({ id => $item })->first;
    return unless $result;
    $result->update({ list_id => $list });
    return $result;
}

sub delete_item {
    my ($self, $item) = @_;
    my $result = $self->schema->resultset('Item')->search({ id => $item })->first;
    return unless $result;
    $result->delete;
    $result = $self->schema->resultset('ItemCount')->search({ item_id => $item })->first;
    $result->delete if $result;
}

sub move_item {
    my ($self, $account, $item, $list) = @_;
    my $result = $self->schema->resultset('Item')->search({ id => $item })->first;
    return unless $result;
    $result->update({ list_id => $list });
    $self->schema->resultset('ItemCount')->update_or_create($account, $item);
    return $result;
}

sub find_account {
    my ($self, $account) = @_;
    my $result = $self->schema->resultset('Account')->search({ id => $account })->first;
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
    return $lists;
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
    my $item = $self->schema->resultset('Item')->create({
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

sub search_username {
    my ($self, $user) = @_;
    my $account = $self->schema->resultset('Account')->search({ username => $user })->first;
    return $account;
}

sub new_user {
    my ($self, $email, $user, $pass) = @_;
    $self->schema->resultset('Account')->create({
        email    => $email,
        username => $user,
        password => $pass,
    });
}

1;
