package Schema::Result::Item;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('items');

__PACKAGE__->add_columns(
    id         => { data_type => 'int', is_nullable => 0, is_serializable => 1, is_auto_increment => 1 },
    name       => { data_type => 'text', is_nullable => 0, is_serializable => 1 },
    note       => { data_type => 'text', is_nullable => 1, is_serializable => 1 },
    category   => { data_type => 'text', is_nullable => 1, is_serializable => 1 },
    cost       => { data_type => 'number', is_nullable => 1, is_serializable => 1 },
    quantity   => { data_type => 'int', is_nullable => 1, is_serializable => 1 },
    account_id => { data_type => 'int', is_nullable => 0, is_serializable => 1 },
    list_id    => { data_type => 'int', is_nullable => 1, is_serializable => 1 },
    assigned   => { data_type => 'int', is_nullable => 1, is_serializable => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(account => 'Schema::Result::Account', 'account_id');
__PACKAGE__->belongs_to(list => 'Schema::Result::List', 'list_id');

1;
