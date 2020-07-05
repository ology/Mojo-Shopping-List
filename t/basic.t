use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use lib $ENV{HOME} . '/sandbox/Test-SQLite/lib';
use Test::SQLite;

use Schema;

my $t = Test::Mojo->new('ShoppingList');

# Setup the test database
my $sqlite = Test::SQLite->new;
$t->app->config->{database} = $sqlite->dsn;
my $schema = Schema->connect($sqlite->dsn);
isa_ok $schema, 'Schema';
$schema->deploy;

# Allow a redirect
$t->ua->max_redirects(1);

# Test that the login form exists
$t->get_ok('/')
  ->status_is(200)
  ->content_like(qr/Login/)
  ->element_exists('form input[name="username"]')
  ->element_exists('form input[name="password"]');

# Test that the signup form exists
$t->get_ok('/signup')
  ->status_is(200)
  ->content_like(qr/Signup/)
  ->element_exists('form input[name="email"]')
  ->element_exists('form input[name="username"]')
  ->element_exists('form input[name="password"]')
  ->element_exists('form input[name="confirm"]');

# Test that a bogus signup fails
$t->post_ok('/signup' => form => {})
  ->status_is(200)
  ->content_like(qr/Invalid fields/);

# Test that a valid signup succeeds
$t->post_ok('/signup' => form => { email => 'test@example.com', username => 'test', password => 'test', confirm => 'test' })
  ->status_is(200)
  ->content_isnt('Invalid fields')
  ->content_like(qr/Login/);

# Test that a bogus login fails
$t->post_ok('/' => form => {})
  ->status_is(200)
  ->content_like(qr/Invalid login/);

# Test that a valid login succeeds
$t->post_ok('/' => form => { username => 'test', password => 'test' })
  ->status_is(200)
  ->content_isnt('Invalid login')
  ->content_like(qr/Logout/);

# Test that the list form exists
$t->get_ok('/a/lists')
  ->status_is(200)
  ->content_like(qr/Shopping lists/)
  ->element_exists('form input[name="name"]');

# Test that a bogus new list fails
$t->post_ok('/a/lists' => form => {})
  ->status_is(200)
  ->content_like(qr/Invalid fields/);

# Test that a valid new list succeeds
$t->post_ok('/a/lists' => form => { name => 'Test List' })
  ->status_is(200)
  ->content_like(qr/Test List/);

# Test that the list name can be updated
$t->post_ok('/a/update_list' => form => { list => 1, name => 'Test List!' })
  ->status_is(200)
  ->content_like(qr/Test List!/);

# Test that the list can be viewed
$t->get_ok('/a/view_list?list=1')
  ->status_is(200)
  ->content_like(qr/Test List!/);

# Test that the query and new item forms exist
$t->get_ok('/a/view_items?list=1&sort=alpha')
  ->status_is(200)
  ->element_exists('form input[name="query"]')
  ->element_exists('form input[name="name"]')
  ->element_exists('form button[type="submit"]');

# Create a new item not on the list
$t->post_ok('/a/new_item' => form => { name => 'Test Item', list => 1, sort => 'alpha' })
  ->status_is(200)
  ->content_like(qr/Test Item/)
  ->element_exists_not('a[title="Go to list"]');

# Create a new item on the list
$t->post_ok('/a/new_item' => form => { name => 'Another Item', list => 1, sort => 'alpha', shop_list => 1 })
  ->status_is(200)
  ->content_like(qr/Another Item/)
  ->element_exists('a[title="Go to list"]');

# Test that querying for an item works
$t->get_ok('/a/view_items' => form => { query => 'another', list => 1, sort => 'alpha' })
  ->status_is(200)
  ->content_like(qr/Another Item/);

# Test that an item can be updated
$t->post_ok('/a/update_item' => form => { active => 0, list => 1, sort => 'alpha', item => 1, name => 'Test Item!' })
  ->status_is(200)
  ->content_like(qr/Test Item!/);

# Test that an item can be deleted
$t->get_ok('/a/delete_item?list=1&sort=alpha&item=2')
  ->status_is(200)
  ->content_isnt('Another Item');

# Test that the list can be deleted
$t->get_ok('/a/delete_list?list=1')
  ->status_is(200)
  ->content_isnt('Test List!');

# Test that the remaining item exists still
$t->get_ok('/a/view_items' => form => { query => 'item', list => 1, sort => 'alpha' })
  ->status_is(200)
  ->content_like(qr/Test Item!/);

done_testing();
