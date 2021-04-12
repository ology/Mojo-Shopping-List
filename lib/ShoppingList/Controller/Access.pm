package ShoppingList::Controller::Access;
use Mojo::Base 'Mojolicious::Controller';

use constant ERROR_MSG => 'Invalid fields';

sub index { shift->render }

sub login {
    my ($self) = @_;
    if (my $user = $self->model->auth($self->param('username'), $self->param('password'))) {
        $self->session(auth => $user->id);
        $self->model->log_user($user->id);
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
    my $lists = $self->model->lists($self->session->{auth});
    $self->render(lists => $lists);
}

sub new_list {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('name', 'not_empty');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
    }
    else {
        $self->model->new_list($self->session->{auth}, $v->param('name'));
    }
    return $self->redirect_to('lists');
}

sub update_list {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list', 'not_empty');
    $v->required('name', 'not_empty');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG)
    }
    else {
        $self->model->update_list($self->session->{auth}, $v->param('list'), $v->param('name'));
    }
    return $self->redirect_to('lists');
}

sub delete_list {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list', 'not_empty');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG)
    }
    else {
        $self->model->delete_list($self->session->{auth}, $v->param('list'));
    }
    return $self->redirect_to('lists');
}

sub view_section {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list');
    $v->optional('sort');
    $v->optional('query');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
#        return $self->redirect_to($self->url_for('view_section')->query(list => $v->param('list'), sort => $v->param('sort'), query => $v->param('query')));
        return $self->redirect_to('/');
    }
    my $account = $self->model->find_account($self->session->{auth});
    unless ($account) {
        return $self->redirect_to('login');
    }
    my $list = $self->model->find_list($self->session->{auth}, $v->param('list'));
    my $name = $list->name;
    my $all_items = $account->items;
    my $names = [];
    while (my $item = $all_items->next) {
        push @$names, $item->name;
    }
    my $query = '';
    if ($v->param('query')) {
      if ($v->param('query') =~ /%/) {
        $query = $v->param('query');
      }
      else {
        $query = '%' . $v->param('query') . '%';
      }
    }
    my $list_items = [];
    if ($query) {
        my $query_items = $self->model->query_items($all_items, $query);
        while (my $item = $query_items->next) {
            push @$list_items, { $item->get_columns };
        }
    }
    my $cats = [];
    my $categories = $self->model->categories($all_items);
    while (my $cat = $categories->next) {
        push @$cats, $cat->category;
    }
    my $lists = $self->model->lists_by_account($account);
    my $shop_lists = [];
    while (my $list = $lists->next) {
        push @$shop_lists, { id => $list->id, name => $list->name };
    }
    $self->render(
        list => $v->param('list'),
        sort => $v->param('sort'),
        query => $v->param('query'),
        items => $list_items,
        names => $names,
        cats => $cats,
        shop_lists => $shop_lists,
        name => $name,
    );
}

sub view_section_items {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list', 'not_empty');
    $v->optional('sort');
    $v->optional('next');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
        return $self->redirect_to('lists');
    }
    if ($v->param('list') == 0) {
        return $self->redirect_to('lists');
    }
    my $sort = '';
    my $on = [];
    my $shop_lists = [];
    my $cats = [];
    my $name = '';
    my $cost = 0;
    my $suggest = '';
    my $suggest_id = 0;
    my $on_items = [];
    $sort = $v->param('sort') || 'alpha';
    my $order = {};
    if ($sort eq 'added') {
        $order = { order_by => 'id' };
    }
    elsif ($sort eq 'alpha') {
        $order = { order_by => { -asc => \'LOWER(name)' } },
    }
    elsif ($sort eq 'category') {
        $order = { order_by => { -asc => [\'LOWER(category)', \'LOWER(name)'] } },
    }
    my %on_cats;
    my $result = $self->model->find_list($self->session->{auth}, $v->param('list'));
    $name = $result->name;
    my $items = $self->model->ordered_items($result, $order);
    # Add the on-items & categories
    while (my $item = $items->next) {
        my $struct = { $item->get_columns };
        push @$on_items, $struct;
        $cost += $item->cost * $item->quantity
            if $item->cost && $item->quantity;
        if ($sort eq 'category') {
            my $cat = $item->category ? ucfirst(lc $item->category) : 'Uncategorized';
            push @{ $on_cats{$cat} }, $struct;
        }
    }
    if ($sort eq 'category') {
        for my $cat ( sort { $a cmp $b } keys %on_cats ) {
            push @$on, { title => $cat };
            push @$on, $_ for @{ $on_cats{$cat} };
        }
    }
    else {
        $on = $on_items;
    }
    my $categories = $self->model->categories($items);
    while (my $cat = $categories->next) {
        push @$cats, $cat->category;
    }
    my $lists = $self->model->account_lists($self->session->{auth});
    while (my $list = $lists->next) {
        push @$shop_lists, { id => $list->id, name => $list->name };
    }
    # Suggestion logic
    my $exclude_cookie = $self->session('exclude') || '';
    my $exclude = [ split /,/, $exclude_cookie ];
    my $list_items = $self->model->list_items($self->session->{auth});
    while (my $item = $list_items->next) {
        push @$exclude, $item->id;
    }
    $result = $self->model->suggestion($self->session->{auth}, $exclude);
    if ($result) {
        my $item = $self->model->find_item($self->session->{auth}, $result->id);
        if (!$item->assigned || $item->assigned == $v->param('list')) {
            $suggest = $item->name;
            $suggest .= ' - ' . $item->note if $item->note;
            $suggest .= '?';
            $suggest_id = $item->id;
            push @$exclude, $result->id;
        }
    }
    if ($suggest) {
        $self->session(exclude => join(',', @$exclude));
    }
    else {
        $suggest = 'Nothing to suggest';
        $self->session(exclude => '');
    }
    $self->render(
        list       => $v->param('list'),
        name       => $name,
        on_items   => $on,
        sort       => $sort,
        cost       => sprintf('%.2f', $cost),
        shop_lists => $shop_lists,
        cats       => $cats,
        suggest    => $suggest,
        suggest_id => $suggest_id,
        next       => $v->param('next'),
    );
}

sub print_list {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list', 'not_empty');
    $v->optional('sort');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
        return $self->redirect_to('lists');
    }
    my $sort = '';
    my $on = [];
    my $off = [];
    my $shop_lists = [];
    my $cats = [];
    my $name = '';
    my $cost = 0;
    my $on_items = [];
    my $off_items = [];
    $sort = $v->param('sort') || 'alpha';
    my $order = {};
    if ($sort eq 'added') {
        $order = { order_by => 'id' };
    }
    elsif ($sort eq 'alpha') {
        $order = { order_by => { -asc => \'LOWER(name)' } },
    }
    elsif ($sort eq 'category') {
        $order = { order_by => { -asc => [\'LOWER(category)', \'LOWER(name)'] } },
    }
    my %on_cats;
    my %off_cats;
    my $result = $self->model->find_list($self->session->{auth}, $v->param('list'));
    $name = $result->name;
    my $items = $self->model->ordered_items($result, $order);
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
    if ($sort eq 'category') {
        for my $cat ( sort { $a cmp $b } keys %on_cats ) {
            push @$on, { title => $cat };
            push @$on, $_ for @{ $on_cats{$cat} };
        }
    }
    else {
        $on = $on_items;
    }
    $self->render(
        list     => $v->param('list'),
        name     => $name,
        on_items => $on,
        sort     => $sort,
        cost     => sprintf('%.2f', $cost),
    );
}

sub update_item {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list', 'not_empty');
    $v->required('item', 'not_empty');
    $v->optional('active', 'not_empty');
    $v->optional('sort');
    $v->optional('name', 'not_empty');
    $v->optional('note', 'not_empty');
    $v->optional('category', 'not_empty');
    $v->optional('cost', 'not_empty');
    $v->optional('quantity', 'not_empty');
    $v->optional('assigned', 'not_empty');
    $v->optional('move_to_list', 'not_empty');
    $v->optional('redirect');
    $v->optional('query');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG)
    }
    else {
        my $quantity = $v->param('quantity');
        my $result = $self->model->find_item($self->session->{auth}, $v->param('item'));
        if ($v->param('active')) {
            if ($v->param('list') && $result->list_id && $v->param('list') != $result->list_id) {
                $self->model->update_or_create($self->session->{auth}, $result->id);
            }
            if ($v->param('move_to_list')) {
                $result->list_id($v->param('move_to_list'));
            }
            else {
                $result->list_id($v->param('list'));
            }
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
    if ($v->param('redirect') eq 'view_section') {
        return $self->redirect_to($self->url_for('view_section')->query(list => $v->param('list'), query => $v->param('query')));
    }
    else {
        return $self->redirect_to($self->url_for('view_section_items')->query(list => $v->param('list'), sort => $v->param('sort')));
    }
}

sub update_item_list {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('item', 'not_empty');
    $v->required('list', 'not_empty');
    $v->optional('sort');
    $v->optional('move_to_list', 'not_empty');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG)
    }
    else {
        my $result = $self->model->update_item_list($self->session->{auth}, $v->param('item'), $v->param('move_to_list'));
        if ($result && $v->param('move_to_list')) {
            $self->model->update_or_create($self->session->{auth}, $result->id);
        }
    }
    return $self->redirect_to($self->url_for('view_section_items')->query(list => $v->param('list'), sort => $v->param('sort')));
}

sub delete_item {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list', 'not_empty');
    $v->required('item', 'not_empty');
    $v->optional('sort');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
    }
    else {
        $self->model->delete_item($self->session->{auth}, $v->param('item'));
    }
    return $self->redirect_to($self->url_for('view_section_items')->query(list => $v->param('list'), sort => $v->param('sort')));
}

sub move_item {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list', 'not_empty');
    $v->required('item', 'not_empty');
    $v->required('move_to_list', 'not_empty');
    $v->optional('sort');
    $v->optional('next');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
    }
    else {
        $self->model->move_item($self->session->{auth}, $v->param('item'), $v->param('move_to_list'));
    }
    return $self->redirect_to($self->url_for('view_section_items')->query(list => $v->param('list'), sort => $v->param('sort'), next => $v->param('next')));
}

sub new_item {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('list', 'not_empty');
    $v->required('name', 'not_empty');
    $v->optional('sort');
    $v->optional('note', 'not_empty');
    $v->optional('category', 'not_empty');
    $v->optional('cost', 'not_empty');
    $v->optional('quantity', 'not_empty');
    $v->optional('shop_list', 'not_empty');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
    }
    else {
        my $item = $self->model->new_item(
            account_id => $self->session->{auth},
            name       => $v->param('name'),
            note       => $v->param('note'),
            category   => $v->param('category'),
            cost       => $v->param('cost'),
            quantity   => $v->param('quantity') || 1,
            list_id    => $v->param('shop_list'),
        );
        if ($v->param('shop_list')) {
            $self->model->update_or_create($self->session->{auth}, $item->id);
        }
    }
    return $self->redirect_to($self->url_for('view_section')->query(list => $v->param('list'), sort => $v->param('sort'), query => $v->param('name')));
}

sub reset {
    my ($self) = @_;
    $self->session(exclude => '');
    return $self->redirect_to($self->url_for('view_section_items')->query(list => $self->param('list'), sort => $self->param('sort')));
}

sub accounts {
    my ($self) = @_;
    # XXX This is brittle:
    return $self->reply->not_found
        unless $self->session->{auth} == 1;
    my $accounts = $self->model->accounts;
    $self->render(accounts => $accounts);
}

sub privacy { shift->render }

sub signup { shift->render }

sub new_user {
    my ($self) = @_;
    my $v = $self->validation;
    $v->required('email');
    $v->required('username')->like(qr/^\w+$/);
    $v->required('password')->size(4, 20);
    $v->required('confirm')->equal_to('password');
    if ($v->has_error) {
        $self->flash(error => ERROR_MSG);
        return $self->redirect_to('signup');
    }
    my $account = $self->model->search_username($v->param('username'));
    if ($account) {
        $self->flash(error => ERROR_MSG);
        return $self->redirect_to('signup');
    }
    $self->model->new_user($v->param('email'), $v->param('username'), $v->param('password'));
    return $self->redirect_to('login');
}

1;
