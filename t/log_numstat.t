# -*- coding: utf-8 -*-

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Git::Repository', 'LogNumstat') }

use Test::Output qw/output_from/;
use Test::Git;
use File::Spec::Functions qw/catfile splitdir catdir/;
use YAML qw/ LoadFile Load DumpFile Dump /;
use Cwd;

my $top = getcwd();
my $test_bundle = "$top/test.bundle";

$ENV{GIT_AUTHOR_EMAIL}    = 'author@example.com';
$ENV{GIT_AUTHOR_NAME}     = 'Author Example';
$ENV{GIT_COMMITTER_EMAIL} = 'committer@example.com';
$ENV{GIT_COMMITTER_NAME}  = 'Committer Example';

{
  my $r = test_repository;

  {
    my $f = 'a.yml';
    DumpFile(catfile($r->work_tree, $f), { numbers => [ 103 .. 200 ] });
    $r->run(add => $f);
    $r->run(commit => -m => "adds $f");
  }

  {
    my ($f, $g) = qw!a.yml b.yml!;
    $r->run(mv => $f => $g);
    $r->run(commit => -m => "renames $f $g");
  }

  {
    my $f = 'c.yml';
    DumpFile(catfile($r->work_tree, $f), { numbers => [ 103 .. 200 ] });
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

  my $self = Git::Repository->new(git_dir => $r->git_dir);
  is ref $self, 'Git::Repository' or diag $self;

  my %tree1;
  {
    my $iterator = $self->log_numstat(qw/ -C --reverse /);
    is ref $iterator, 'Git::Repository::LogNumstat::Iterator' or diag $iterator;
    while (my $log = $iterator->next) {
      is ref $log, 'Git::Repository::Log' or diag ref $log;
      can_ok($log, qw/commit numstat/);
      for ($log->numstat) {
        is ref $_, 'Git::Repository::LogNumstat' or diag ref $_;
        can_ok($_, qw/added deleted path/) or diag explain $_;
        $tree1{($_->path)[-1]} = $_->added - $_->deleted;
        # diag join "\t" => $_->added => $_->deleted
        #  => join(" => ", $_->path), "\n";
      }
    }
  }

  my %tree2;
  {
    my @iterator = $self->log_numstat(qw/ -C --reverse --diffstat /);
    for my $log (@iterator) {
      is ref $log, 'Git::Repository::Log' or diag ref $log;
      can_ok($log, qw/commit numstat/);
      for ($log->numstat) {
        is ref $_, 'Git::Repository::LogNumstat' or diag ref $_;
        can_ok($_, qw/added deleted path/) or diag explain $_;
        $tree2{($_->path)[-1]} = $_->added - $_->deleted;
        # diag join "\t" => $_->added => $_->deleted
        #  => join(" => ", $_->path), "\n";
      }
    }
  }
  # diag explain \%tree1;

  is_deeply \%tree1, \%tree2 or diag explain [ \%tree1, \%tree2 ];
}

unlink $test_bundle;

done_testing();
