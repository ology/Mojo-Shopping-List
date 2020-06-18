package Schema::ResultSet::ItemCount;
use strict;
use warnings;
use parent 'Schema::ResultSet';

sub update_or_create {
    my ($self, $account_id, $item_id) = @_;

    die 'Required arguments not given' unless $account_id && $item_id;

    my $item_count = $self->search({ item_id => $item_id })->first;

    if ($item_count) {
        $item_count->update({ count => $item_count->count + 1 });
    }
    else {
        $item_count = $self->create({
            count      => 1,
            account_id => $account_id,
            item_id    => $item_id,
        });
    }

    return $item_count;
}

1;
