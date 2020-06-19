package Mojolicious::Plugin::Helper;
use Mojo::Base 'Mojolicious::Plugin';

use Schema;

sub register {
    my ( $self, $app ) = @_;

    $app->helper( schema => sub {
        my ($c) = @_;
        return state $schema = Schema->connect( $c->config('database'), '', '' );
    } );

    $app->helper(rs => sub {
        return shift->schema->resultset(@_);
    });

    $app->helper( auth => sub {
        my ( $c, $user, $pass ) = @_;

        my $result = $c->schema->resultset('Account')->search({ username => $user })->first;

        return $result
            if $result && $result->check_password($pass);
    } );

}

1;
