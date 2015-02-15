# -*- coding: utf-8 -*-

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Git::Repository', 'LogNumstat') }

use Test::Output qw/output_from/;
use Test::Exception;
use Test::Git;
use File::Spec::Functions qw/catfile splitdir catdir/;
use File::Copy;
use YAML qw/ LoadFile Load DumpFile Dump /;
use Config;
use Cwd;

my $top = getcwd();
my $test_bundle = "$top/test.bundle";

$ENV{GIT_AUTHOR_EMAIL}    = 'author@example.com';
$ENV{GIT_AUTHOR_NAME}     = 'Author Example';
$ENV{GIT_COMMITTER_EMAIL} = 'committer@example.com';
$ENV{GIT_COMMITTER_NAME}  = 'Committer Example';

sub can_run {
  my ($cmd) = @_;
  for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
    next if $dir eq '';
    my $abs = catfile($dir, $cmd);
    return $abs if -x $abs;
  }
  undef;
}

{
  my $r = test_repository;

  {
    my $f = 'a.yml';
    DumpFile(catfile($r->work_tree, $f), { num => [ 103 .. 200 ] });
    $r->run(add => $f);
    $r->run(commit => -m => "adds $f");
  }

  {
    my ($f, $g) = qw!a.yml b.yml!;
    DumpFile(catfile($r->work_tree, $f), { num => [ 103 .. 199 ],
                                           abc => [ 'a' .. 'c' ],
                                         });
    $r->run(add => $f);
    $r->run(mv => $f => $g);
    $r->run(commit => -m => "renames $f $g");
  }

  {
    my $f = 'c.yml';
    DumpFile(catfile($r->work_tree, $f), { num => [ 103 .. 200 ] });
    $r->run(add => $f);
    $r->run(commit => -m => "adds $f");
  }

  {
    my ($f, $g) = qw!c.yml x/c.yml!;
    mkdir catfile($r->work_tree, 'x');
    $r->run(mv => $f => $g);
    $r->run(commit => -m => "renames $f $g");
  }

  {
    my ($f, $g) = qw!x/c.yml x/d.yml!;
    $r->run(mv => $f => $g);
    $r->run(commit => -m => "renames $f $g");
  }

  $r->run(tag => 'RELENG');
  $r->run(bundle => create => $test_bundle => HEAD => '--all');

  {
    my $f = catfile($r->work_tree, 'test.bundle');
    copy($test_bundle, $f);
    $r->run(add => $f);
    $r->run(commit => -m => "adds binary $f");
  }

  {
    my $f = catfile($r->work_tree, 'test.bundle');
    copy($test_bundle, $f);
    $r->run(add => $f);
    $r->run(commit => -m => "adds binary $f");
  }

  my $self = Git::Repository->new(git_dir => $r->git_dir);
  is ref $self, 'Git::Repository' or diag $self;

  {
    local $ENV{GIT_DIR} = $r->git_dir;
    lives_ok { Git::Repository->log_numstat() };
  }

  {
    # option
    lives_ok { $self->log_numstat()->next };
    lives_ok { $self->log_numstat(qw/ --numstat /)->next };
    # lives_ok { $self->log_numstat(qw/ --diffstat /)->next };

    my $it = $self->log_numstat(qw/ --numstat -- --stat /);
    is grep(/--stat/, @{$it->{cmd}{cmdline}}), 1;

    # bad option
    dies_ok  { $self->log_numstat(qw/ --stat /) };
    dies_ok  { $self->log_numstat(qw/ --dirstat /) };
    dies_ok  { $self->log_numstat(qw/ --shortstat /) };
    dies_ok  { $self->log_numstat(qw/ --patch-with-stat /) };
  }

  {
    if (can_run('diffstat')) {
      lives_ok  { $self->log_numstat(qw/ --diffstat /)->next };
    } else {
      throws_ok { $self->log_numstat(qw/ --diffstat /)->next }
        qr/open2: exec of diffstat/;
    }
  }

  {
    # encoding
    lives_ok { $self->log_numstat(qw/ :utf8 /)->next };
    lives_ok { $self->log_numstat(qw/ :utf8 --numstat /)->next };

    # bad encoding
    dies_ok  { $self->log_numstat(qw/ --numstat :utf8 /)->next };

    my $it1 = Git::Repository->log_numstat(qw/ :utf8 --numstat /);
    is $it1->encoding, 'utf8';

    my $it2 = Git::Repository->log_numstat(qw/ :encoding(UTF-8) --numstat /);
    is $it2->encoding, 'encoding(UTF-8)';

    my $it3 = Git::Repository->log_numstat(qw/ --numstat :utf8 /);
    is $it3->encoding, undef;
    # diag join ' ' =>  @{$it3->{cmd}{cmdline}};

    $it3->encoding('encoding(UTF-8)');
    is $it3->encoding, 'encoding(UTF-8)';
  }

  for my $opts (
    [],
    [qw/ --numstat /],
    [qw/ --numstat --reverse -C /],
    [qw/ --diffstat /],
    [qw/ :utf8 --diffstat /],
    [qw/ --diffstat --reverse -C /],
   ) {
    if ((grep {/--diffstat/} @$opts) && !can_run('diffstat')) {
      diag join ' ' => ('log_numstat()', @$opts, '...', 'ignored');
      next;
    }
    my %tree;
    my $iterator = $self->log_numstat(@$opts);
    is ref $iterator, 'Git::Repository::LogNumstat::Iterator' or diag $iterator;
    # diag join ' ' => @{$iterator->{cmd}{cmdline}};
    while (my $log = $iterator->next) {
      is ref $log, 'Git::Repository::Log' or diag ref $log;
      can_ok($log, qw/commit numstat/);
      # diag $log->commit;
      for ($log->numstat) {
        is ref $_, 'Git::Repository::LogNumstat' or diag ref $_;
        can_ok($_, qw/added deleted path/) or diag explain $_;
        # diag join "\t" => $_->added => $_->deleted
        #  => join(" => ", $_->path), "\n";
        my @p = $_->path;
        if (@p > 1) {
          $tree{$p[1]} = $tree{$p[0]};
          delete $tree{$p[0]} unless $_->added || $_->deleted;
        }
        $tree{$p[-1]} += $_->added - $_->deleted;
      }
    }
    my $d;
    is $tree{'b.yml'}, 103 or $d++;
    is $tree{'x/d.yml'}, 100 or $d++;
    is $tree{'test.bundle'}, undef or $d++;
    $d and diag explain \%tree;
    last if $d;

    for my $log ($self->log_numstat(@$opts)) {
      is ref $log, 'Git::Repository::Log' or diag ref $log;
      can_ok($log, qw/commit numstat/);
    }
  }

}

unlink $test_bundle;

done_testing();
