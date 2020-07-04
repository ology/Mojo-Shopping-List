package Mojolicious::Plugin::Helper;
use Mojo::Base 'Mojolicious::Plugin';

use ShoppingList::Model;
use Schema;

sub register {
    my ($self, $app) = @_;

    $app->helper(schema => sub {
        my ($c) = @_;
        return state $schema = Schema->connect($c->config('database'), '', '');
    });

    $app->helper(model => sub {
        my ($c) = @_;
        return state $model = ShoppingList::Model->new(schema => $c->schema);
    });

}

1;
