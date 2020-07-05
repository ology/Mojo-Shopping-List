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
$t->ua->max_redirects(2);

# Test that a valid signup succeeds
$t->post_ok('/signup' => form => { email => 'test@example.com', username => 'test', password => 'test', confirm => 'test' })
  ->status_is(200)
  ->content_isnt('Invalid fields')
  ->content_like(qr/Login/);

# Test that a valid login succeeds
$t->post_ok('/' => form => { username => 'test', password => 'test' })
  ->status_is(200)
  ->content_isnt('Invalid login')
  ->content_like(qr/Logout/);

# Test that a valid new list succeeds
$t->post_ok('/lists' => form => { name => 'Test List' })
  ->status_is(200)
  ->content_like(qr/Test List/);

# Test that the wrong list cannot be updated
$t->post_ok('/update_list' => form => { list => 2, name => 'Test List!' })
  ->status_is(200)
  ->content_like(qr/Invalid fields/);

# Test that the list can be viewed
$t->get_ok('/view_list?list=1')
  ->status_is(200)
  ->content_like(qr/Test List/);

# Create a new item not on the list
$t->post_ok('/new_item' => form => { name => 'Test Item', list => 1, sort => 'alpha' })
  ->status_is(200)
  ->content_like(qr/Test Item/)
  ->element_exists_not('a[title="Go to list"]');

# Test that a wrong item cannot be updated
$t->post_ok('/update_item' => form => { active => 0, list => 1, sort => 'alpha', item => 2, name => 'Test Item!' })
  ->status_is(200)
  ->content_like(qr/Invalid fields/);

# Test that an item cannot be updated on the wrong list
$t->post_ok('/update_item' => form => { active => 0, list => 2, sort => 'alpha', item => 1, name => 'Test Item!' })
  ->status_is(200)
  ->content_like(qr/Invalid fields/);

# Test that a wrong item cannot be deleted
$t->get_ok('/delete_item?list=1&sort=alpha&item=2')
  ->status_is(200)
  ->content_like(qr/Invalid fields/);

# Test that an item cannot be deleted from the wrong list
$t->get_ok('/delete_item?list=2&sort=alpha&item=1')
  ->status_is(200)
  ->content_like(qr/Invalid fields/);

# Test that the wrong list cannot be deleted
$t->get_ok('/delete_list?list=2')
  ->status_is(200)
  ->content_like(qr/Invalid fields/);

done_testing();
