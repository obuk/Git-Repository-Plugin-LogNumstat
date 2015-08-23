# -*- coding: utf-8 -*-

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Git::Repository', 'Log::Numstat') }

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
    can_ok($r, 'log_numstat');
    my $iter = $r->log_numstat();
    isa_ok $iter, 'Git::Repository::Log::Iterator';
    my $log = $iter->next;
    can_ok $log, 'numstat';
  }

  {
    local $ENV{GIT_DIR} = $r->git_dir;
    my $R = 'Git::Repository';
    can_ok($R, 'log_numstat');
    my $iter = $R->log_numstat();
    isa_ok $iter, 'Git::Repository::Log::Iterator';
    my $log = $iter->next;
    can_ok $log, 'numstat';
  }

  {
    local $ENV{GIT_DIR} = $r->git_dir;
    my $R = 'Git::Repository';
    my @log = $R->log_numstat();
    is scalar @log, 6;
    can_ok $log[0], 'numstat';
  }

}

unlink $test_bundle if $test_bundle;

done_testing();
