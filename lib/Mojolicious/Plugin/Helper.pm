package Mojolicious::Plugin::Helper;
use Mojo::Base 'Mojolicious::Plugin';

use Schema;
use ShoppingList::Model;

use Encoding::FixLatin qw(fix_latin);

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

    $app->helper(fix_latin => sub {
        my ($c, $string) = @_;
        return fix_latin($string);
    });

}

1;
