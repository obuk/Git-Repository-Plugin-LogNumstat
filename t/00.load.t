use Test::More;

BEGIN {
  use_ok( 'Git::Repository::Plugin::LogNumstat' );
  use_ok( 'Git::Repository::LogNumstat' );
  use_ok( 'Git::Repository::LogNumstat::Iterator' );
}

for (qw/ Git::Repository::Plugin::LogNumstat /) {
  diag "Testing $_ " . eval '$' . $_ . '::VERSION'
}

done_testing();
