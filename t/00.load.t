use Test::More;

BEGIN {
  use_ok( 'Git::Repository::Plugin::Log::Numstat' );
}

for (qw/ Git::Repository::Plugin::Log::Numstat /) {
  diag "Testing $_ " . eval '$' . $_ . '::VERSION'
}

done_testing();
