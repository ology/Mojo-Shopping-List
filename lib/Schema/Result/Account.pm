package Schema::Result::Account;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('accounts');

__PACKAGE__->load_components(qw/EncodedColumn/);

__PACKAGE__->add_columns(
    id       => { data_type => 'int', is_nullable => 0, is_serializable => 1, is_auto_increment => 1 },
    email    => { data_type => 'text', is_nullable => 0, is_serializable => 1 },
    username => { data_type => 'text', is_nullable => 0, is_serializable => 1 },
    password => { data_type => 'text', is_nullable => 0, is_serializable => 1,
        encode_column => 1,
        encode_class => 'Crypt::Eksblowfish::Bcrypt',
        encode_args => { key_nul => 0, cost => 6 },
        encode_check_method => 'check_password',
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(lists => 'Schema::Result::List', 'account_id');
__PACKAGE__->has_many(items => 'Schema::Result::Item', 'account_id');

1;
