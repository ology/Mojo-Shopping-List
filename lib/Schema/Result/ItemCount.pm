package Schema::Result::ItemCount;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('item_counts');

__PACKAGE__->add_columns(
    id         => { data_type => 'int', is_nullable => 0, is_serializable => 1, is_auto_increment => 1 },
    count      => { data_type => 'int', is_nullable => 1, is_serializable => 1 },
    item_id    => { data_type => 'int', is_nullable => 0, is_serializable => 1 },
    account_id => { data_type => 'int', is_nullable => 0, is_serializable => 1 },
);

__PACKAGE__->set_primary_key('id');

1;
