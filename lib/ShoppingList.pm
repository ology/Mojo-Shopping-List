package ShoppingList;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->plugin('Helper');

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  # Configure the application
  $self->secrets($config->{secrets});

  # Router
  my $r = $self->routes;

  # Authorization
  my $auth = $r->under('/' => sub {
    my ($self) = @_;

    my $session = $self->session('auth') // '';

    return 1
        if $session;

    $self->render(text => 'Denied!');
    return 0;
  });

  # Routes
  $r->get('/')->to('access#index')->name('login');
  $r->post('/')->to('access#login');
  $r->get('/logout')->to('access#logout')->name('logout');
  $auth->get('/lists')->to('access#lists')->name('lists');
  $auth->post('/lists')->to('access#new_list');
  $auth->post('/update_list')->to('access#update_list');
  $auth->get('/delete_list')->to('access#delete_list');
  $auth->get('/view_list')->to('access#view_list')->name('view_list');
  $auth->get('/print_list')->to('access#print_list');
  $auth->post('/new_item')->to('access#new_item');
  $auth->post('/update_item')->to('access#update_item');
  $auth->get('/delete_item')->to('access#delete_item');
  $auth->post('/move_item')->to('access#move_item');
  $auth->get('/view_items')->to('access#view_items');
}

1;
