package ShoppingList::Controller::Access;
use Mojo::Base 'Mojolicious::Controller';

use constant ERROR_MSG => 'Invalid fields';

sub index { shift->render }

sub login {
    my ($self) = @_;
    if (my $user = $self->auth($self->param('username'), $self->param('password'))) {
        $self->session(auth => $user->id);
        return $self->redirect_to('lists');
    }
    $self->flash(error => 'Invalid login');
    return $self->redirect_to('login');
}

sub logout {
    my ($self) = @_;
    delete $self->session->{auth};
    return $self->redirect_to('login');
}

sub lists {
    my ($self) = @_;
    my $account = $self->schema->resultset('Account')->find($self->session->{auth});
    my $lists = $account->lists->search({}, { order_by => { '-asc' => \'LOWER(name)' } });
    $self->render(lists => $lists);
}

sub new_list {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('name');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
    }
    else {
        $self->schema->resultset('List')->create({
            name       => $v->param('name'),
            account_id => $self->session->{auth},
        });
    }
    return $self->redirect_to('lists');
}

sub update_list {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list');
    $v->required('name');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG)
    }
    else {
        my $result = $self->schema->resultset('List')->find($v->param('list'));
        $result->update({ name => $v->param('name') });
    }
    return $self->redirect_to('lists');
}

sub delete_list {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG)
    }
    else {
        my $result = $self->schema->resultset('List')->find($v->param('list'));
        $result->delete;
    }
    return $self->redirect_to('lists');
}

sub view_list {
    my ($self) = @_;
    my $sort = '';
    my $on = [];
    my $off = [];
    my $shop_lists = [];
    my $cats = [];
    my $name = '';
    my $cost = 0;
    my $v = $self->validation;
    $v->required('list');
    $v->optional('sort');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
        return $self->redirect_to('lists');
    }
    else {
        my $on_items = [];
        my $off_items = [];
        $sort = $v->param('sort') || 'alpha';
        my $order = {};
        if ($sort eq 'added') {
            $order = { order_by => 'id' };
        }
        elsif ($sort eq 'alpha') {
            $order = { order_by => { '-asc' => \'LOWER(name)' } },
        }
        elsif ($sort eq 'category') {
            $order = { order_by => { '-asc' => [\'LOWER(category)', \'LOWER(name)'] } },
        }
        my %on_cats;
        my %off_cats;
        my $result = $self->schema->resultset('List')->find($v->param('list'));
        $name = $result->name;
        my $items = $result->items->search({}, { %$order });
        while (my $item = $items->next) {
            my $struct = {
                id       => $item->id,
                name     => $item->name,
                category => $item->category,
                note     => $item->note,
                quantity => $item->quantity,
                cost     => $item->cost,
                list_id  => $item->list_id,
                assigned => $item->assigned,
            };
            push @$on_items, $struct;
            $cost += $item->cost * $item->quantity
                if $item->cost && $item->quantity;
            if ($sort eq 'category') {
                my $cat = $item->category ? ucfirst(lc $item->category) : 'Uncategorized';
                push @{ $on_cats{$cat} }, $struct;
            }
        }
        $items = $self->schema->resultset('Item')->search(
            {
                account_id => $self->session->{auth},
                list_id    => undef,
            },
            {
                %$order,
            }
        );
        while (my $item = $items->next) {
            next if $item->assigned && $item->assigned != $v->param('list');
            my $struct = {
                id       => $item->id,
                name     => $item->name,
                category => $item->category,
                note     => $item->note,
                quantity => $item->quantity,
                cost     => $item->cost,
                list_id  => $item->list_id,
                assigned => $item->assigned,
            };
            push @$off_items, $struct;
            if ($sort eq 'category') {
                my $cat = $item->category ? ucfirst(lc $item->category) : 'Uncategorized';
                push @{ $off_cats{$cat} }, $struct;
            }
        }
        if ($sort eq 'category') {
            for my $cat ( sort { $a cmp $b } keys %on_cats ) {
                push @$on, { title => $cat };
                push @$on, $_ for @{ $on_cats{$cat} };
            }
            for my $cat ( sort { $a cmp $b } keys %off_cats ) {
                push @$off, { title => $cat };
                push @$off, $_ for @{ $off_cats{$cat} };
            }
        }
        else {
            $on = $on_items;
            $off = $off_items;
        }
        my $categories = $items->search(
            {},
            {
                distinct => 1,
                columns  => [qw/category/],
                order_by => { '-asc' => 'category' },
            }
        );
        while (my $cat = $categories->next) {
            push @$cats, $cat->category;
        }
        my $lists = $self->schema->resultset('List')->search(
            {
                account_id => $self->session->{auth},
            },
            {
                order_by => { '-asc' => 'name' },
            }
        );
        while (my $list = $lists->next) {
            push @$shop_lists, { id => $list->id, name => $list->name };
        }
    }
    $self->render(
        list       => $v->param('list'),
        name       => $name,
        on_items   => $on,
        off_items  => $off,
        sort       => $sort,
        cost       => sprintf('%.2f', $cost),
        shop_lists => $shop_lists,
        cats       => $cats,
    );
}

sub print_list {
    my ($self) = @_;
    my $sort = '';
    my $on = [];
    my $off = [];
    my $shop_lists = [];
    my $cats = [];
    my $name = '';
    my $cost = 0;
    my $v = $self->validation;
    $v->required('list');
    $v->optional('sort');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
        return $self->redirect_to('lists');
    }
    else {
        my $on_items = [];
        my $off_items = [];
        $sort = $v->param('sort') || 'alpha';
        my $order = {};
        if ($sort eq 'added') {
            $order = { order_by => 'id' };
        }
        elsif ($sort eq 'alpha') {
            $order = { order_by => { '-asc' => \'LOWER(name)' } },
        }
        elsif ($sort eq 'category') {
            $order = { order_by => { '-asc' => [\'LOWER(category)', \'LOWER(name)'] } },
        }
        my %on_cats;
        my %off_cats;
        my $result = $self->schema->resultset('List')->find($v->param('list'));
        $name = $result->name;
        my $items = $result->items->search({}, { %$order });
        while (my $item = $items->next) {
            my $struct = {
                id       => $item->id,
                name     => $item->name,
                category => $item->category,
                note     => $item->note,
                quantity => $item->quantity,
                cost     => $item->cost,
                list_id  => $item->list_id,
                assigned => $item->assigned,
            };
            push @$on_items, $struct;
            $cost += $item->cost * $item->quantity
                if $item->cost && $item->quantity;
            if ($sort eq 'category') {
                my $cat = $item->category ? ucfirst(lc $item->category) : 'Uncategorized';
                push @{ $on_cats{$cat} }, $struct;
            }
        }
        $items = $self->schema->resultset('Item')->search(
            {
                account_id => $self->session->{auth},
                list_id    => undef,
            },
            {
                %$order,
            }
        );
        while (my $item = $items->next) {
            next if $item->assigned && $item->assigned != $v->param('list');
            my $struct = {
                id       => $item->id,
                name     => $item->name,
                category => $item->category,
                note     => $item->note,
                quantity => $item->quantity,
                cost     => $item->cost,
                list_id  => $item->list_id,
                assigned => $item->assigned,
            };
            push @$off_items, $struct;
            if ($sort eq 'category') {
                my $cat = $item->category ? ucfirst(lc $item->category) : 'Uncategorized';
                push @{ $off_cats{$cat} }, $struct;
            }
        }
        if ($sort eq 'category') {
            for my $cat ( sort { $a cmp $b } keys %on_cats ) {
                push @$on, { title => $cat };
                push @$on, $_ for @{ $on_cats{$cat} };
            }
            for my $cat ( sort { $a cmp $b } keys %off_cats ) {
                push @$off, { title => $cat };
                push @$off, $_ for @{ $off_cats{$cat} };
            }
        }
        else {
            $on = $on_items;
            $off = $off_items;
        }
    }
    $self->render(
        list      => $v->param('list'),
        name      => $name,
        on_items  => $on,
        off_items => $off,
        sort      => $sort,
        cost      => sprintf('%.2f', $cost),
    );
}

sub update_item {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list');
    $v->required('item');
    $v->optional('active');
    $v->optional('sort');
    $v->optional('name');
    $v->optional('note');
    $v->optional('category');
    $v->optional('cost');
    $v->optional('quantity');
    $v->optional('assigned');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG)
    }
    else {
        my $quantity = $v->param('quantity');
        my $result = $self->schema->resultset('Item')->find($v->param('item'));
        if ($v->param('active')) {
            $result->list_id($v->param('list'));
            $quantity ||= 1;
        }
        else {
            $result->list_id(undef);
        }
        $result->assigned($v->param('assigned'));
        $result->name($v->param('name')) if $v->param('name');
        $result->note($v->param('note'));
        $result->category($v->param('category'));
        $result->cost($v->param('cost'));
        $result->quantity($quantity);
        $result->update;
    }
    return $self->redirect_to('/view_list?list=' . $v->param('list') . '&sort=' . $v->param('sort'));
}

sub update_item_list {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('item');
    $v->required('list');
    $v->required('query');
    $v->optional('move_to_list');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG)
    }
    else {
        my $result = $self->schema->resultset('Item')->find($v->param('item'));
        $result->update({ list_id => $v->param('move_to_list') });
    }
    return $self->redirect_to('/view_items?list=' . $v->param('list') . '&sort=' . $v->param('sort') . '&query=' . $v->param('query'));
}

sub delete_item {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list');
    $v->required('item');
    $v->optional('sort');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
    }
    else {
        my $result = $self->schema->resultset('Item')->find($v->param('item'));
        $result->delete;
    }
    return $self->redirect_to('/view_list?list=' . $v->param('list') . '&sort=' . $v->param('sort'));
}

sub move_item {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list');
    $v->required('item');
    $v->required('move_to_list');
    $v->optional('sort');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
    }
    else {
        my $result = $self->schema->resultset('Item')->find($v->param('item'));
        $result->update({ list_id => $v->param('move_to_list') });
    }
    return $self->redirect_to('/view_list?list=' . $v->param('list') . '&sort=' . $v->param('sort'));
}

sub view_items {
    my ($self) = @_;
    my $names = [];
    my $cats = [];
    my $shop_lists = [];
    my $list_items;
    my $v = $self->validation;
    $v->required('list');
    $v->optional('sort');
    $v->optional('query');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
    }
    else {
        my $all_items = $self->schema->resultset('Item')->search(
            {
                account_id => $self->session->{auth},
            }
        );
        while (my $item = $all_items->next) {
            push @$names, $item->name;
        }
        my $categories = $all_items->search(
            {},
            {
                distinct => 1,
                columns  => [qw/category/],
                order_by => { '-asc' => 'category' },
            }
        );
        while (my $cat = $categories->next) {
            push @$cats, $cat->category;
        }
        my $lists = $self->schema->resultset('List')->search(
            {
                account_id => $self->session->{auth},
            },
            {
                order_by => { '-asc' => \'LOWER(name)' },
            }
        );
        while (my $list = $lists->next) {
            push @$shop_lists, { id => $list->id, name => $list->name };
        }
        my $query = $v->param('query') ? '%' . $v->param('query') . '%' : '';
        $list_items = $all_items->search(
            {
                -or => [
                    name     => { like => $query },
                    note     => { like => $query },
                    category => { like => $query },
                ],
            },
            {
                order_by => { '-asc' => \'LOWER(name)' },
            }
        );
    }
    $self->render(
        list       => $v->param('list'),
        sort       => $v->param('sort'),
        query      => $v->param('query'),
        names      => $names,
        shop_lists => $shop_lists,
        cats       => $cats,
        items      => $list_items,
    );
}

sub new_item {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list');
    $v->required('name');
    $v->optional('sort');
    $v->optional('note');
    $v->optional('category');
    $v->optional('cost');
    $v->optional('quantity');
    $v->optional('shop_list');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
    }
    else {
        $self->schema->resultset('Item')->create({
            account_id => $self->session->{auth},
            name       => $v->param('name'),
            note       => $v->param('note'),
            category   => $v->param('category'),
            cost       => $v->param('cost'),
            quantity   => $v->param('quantity'),
            list_id    => $v->param('shop_list'),
        });
    }
    return $self->redirect_to('/view_items?list=' . $v->param('list') . '&sort=' . $v->param('sort') . '&query=' . $v->param('name'));
}

1;
