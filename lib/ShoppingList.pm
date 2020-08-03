package ShoppingList;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  $self->plugin('Helper');

  my $config = $self->plugin('Config');

  $self->secrets($config->{secrets});

  my $r = $self->routes;

  my $auth = $r->under('/a' => sub {
    my ($self) = @_;
    my $session = $self->session('auth') // '';
    return 1 if $session;
    $self->redirect_to('login');
    return 0;
  });

  $r->get('/')->to('access#index')->name('login');
  $r->post('/')->to('access#login')->name('auth');
  $r->get('/logout')->to('access#logout');
  $r->get('/signup')->to('access#signup');
  $r->post('/signup')->to('access#new_user')->name('new_user');
  $r->get('/privacy')->to('access#privacy');
  $auth->get('/lists')->to('access#lists');
  $auth->post('/lists')->to('access#new_list')->name('new_list');
  $auth->post('/update_list')->to('access#update_list');
  $auth->get('/delete_list')->to('access#delete_list');
  $auth->get('/view_list')->to('access#view_list');
  $auth->get('/print_list')->to('access#print_list');
  $auth->post('/new_item')->to('access#new_item');
  $auth->post('/update_item')->to('access#update_item');
  $auth->get('/delete_item')->to('access#delete_item');
  $auth->post('/move_item')->to('access#move_item');
  $auth->get('/view_items')->to('access#view_items');
  $auth->post('/update_item_list')->to('access#update_item_list');
  $auth->get('/reset')->to('access#reset');
}

1;
