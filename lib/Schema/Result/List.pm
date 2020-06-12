package Schema::Result::List;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('lists');

__PACKAGE__->add_columns(
    id         => { data_type => 'int', is_nullable => 0, is_serializable => 1, is_auto_increment => 1 },
    name       => { data_type => 'text', is_nullable => 0, is_serializable => 1 },
    account_id => { data_type => 'int', is_nullable => 0, is_serializable => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(items => 'Schema::Result::Item', 'list_id');

1;
