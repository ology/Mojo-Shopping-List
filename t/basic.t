use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use lib $ENV{HOME} . '/sandbox/Test-SQLite/lib';
use Test::SQLite;

use Schema;

my $t = Test::Mojo->new('ShoppingList');

my $sqlite = Test::SQLite->new;
$t->app->config->{database} = $sqlite->dsn;
my $schema = Schema->connect($sqlite->dsn);
isa_ok $schema, 'Schema';
$schema->deploy;

$t->ua->max_redirects(1);

$t->get_ok('/')
  ->status_is(200)
  ->content_like(qr/Login/)
  ->element_exists('form input[name="username"]')
  ->element_exists('form input[name="password"]');

$t->get_ok('/signup')
  ->status_is(200)
  ->content_like(qr/Signup/)
  ->element_exists('form input[name="email"]')
  ->element_exists('form input[name="username"]')
  ->element_exists('form input[name="password"]')
  ->element_exists('form input[name="confirm"]');

$t->post_ok('/signup' => form => {})
  ->status_is(200)
  ->content_like(qr/Invalid fields/);

$t->post_ok('/signup' => form => { email => 'test@example.com', username => 'test', password => 'test', confirm => 'test' })
  ->status_is(200)
  ->content_isnt('Invalid fields')
  ->content_like(qr/Login/);

$t->post_ok('/' => form => {})
  ->status_is(200)
  ->content_like(qr/Invalid login/);

$t->post_ok('/' => form => { username => 'test', password => 'test' })
  ->status_is(200)
  ->content_isnt('Invalid login')
  ->content_like(qr/Logout/);

$t->get_ok('/lists')
  ->status_is(200)
  ->content_like(qr/Shopping lists/)
  ->element_exists('form input[name="name"]');

$t->post_ok('/lists' => form => {})
  ->status_is(200)
  ->content_like(qr/Invalid fields/);

$t->post_ok('/lists' => form => { name => 'Test List' })
  ->status_is(200)
  ->content_like(qr/Test List/);

$t->post_ok('/update_list' => form => { list => 1, name => 'Test List!' })
  ->status_is(200)
  ->content_like(qr/Test List!/);

$t->get_ok('/view_list?list=1')
  ->status_is(200)
  ->content_like(qr/Test List!/);

$t->get_ok('/view_items?list=1&sort=alpha')
  ->status_is(200)
  ->element_exists('form input[name="query"]')
  ->element_exists('form input[name="name"]')
  ->element_exists('form button[type="submit"]');

$t->post_ok('/new_item' => form => { name => 'Test Item', list => 1, sort => 'alpha' })
  ->status_is(200)
  ->content_like(qr/Test Item/)
  ->element_exists_not('a[title="Go to list"]');

$t->post_ok('/new_item' => form => { name => 'Another Item', list => 1, sort => 'alpha', shop_list => 1 })
  ->status_is(200)
  ->content_like(qr/Another Item/)
  ->element_exists('a[title="Go to list"]');

$t->get_ok('/view_items' => form => { query => 'another', list => 1, sort => 'alpha' })
  ->status_is(200)
  ->content_like(qr/Another Item/);

$t->post_ok('/update_item' => form => { active => 0, list => 1, sort => 'alpha', item => 1, name => 'Test Item!' })
  ->status_is(200)
  ->content_like(qr/Test Item!/);

$t->get_ok('/delete_item?list=1&sort=alpha&item=2')
  ->status_is(200)
  ->content_isnt('Another Item');

$t->get_ok('/delete_list?list=1')
  ->status_is(200)
  ->content_isnt('Test List!');

$t->get_ok('/view_items' => form => { query => 'item', list => 1, sort => 'alpha' })
  ->status_is(200)
  ->content_like(qr/Test Item!/);

done_testing();
