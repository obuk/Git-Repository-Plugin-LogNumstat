package Git::Repository::Log::Numstat;

use strict;
use warnings;
use 5.006;

use Carp;
use Git::Repository::Log;
our @ISA = qw( Git::Repository::Log );

use Git::Repository::Plugin::Log::Numstat;
*VERSION = \$Git::Repository::Plugin::Log::Numstat::VERSION;

{
  package Git::Repository::Log::Numstat::Item;
  sub added   {    $_[0]->{added}     }
  sub deleted {    $_[0]->{deleted}   }
  sub path    { @{ $_[0]->{path}    } }
  sub new {
    my ($class, $added, $deleted) = splice(@_, 0, 3);
    bless { added => $added, deleted => $deleted, path => [@_] };
  }
}

sub numstat {
  my ($log) = @_;
  my $item = 'Git::Repository::Log::Numstat::Item';
  if ($log->{_numstat}) {
    unless (exists $log->{numstat}) {
      my @numstat = ();
      for (split /\n/, $log->extra) {
        next unless my ($added, $deleted, $path) =
          /^
           (\d+) \s+                # added
           (\d+) \s+                # deleted
           (.*)                     # path
          /x;
        if ($path =~ /{(.*) => (.*)}/) {
          my $from = $`.$1.$';
          my $to   = $`.$2.$';
          push @numstat, $item->new($added, $deleted, $from, $to);
        } elsif ($path =~ /(.*) => (.*)/) {
          my $from = $1;
          my $to   = $2;
          push @numstat, $item->new($added, $deleted, $from, $to);
        } else {
          push @numstat, $item->new($added, $deleted, $path);
        }
      }
      $log->{numstat} = \@numstat;
    }
    @{ $log->{numstat} };
  } else {
    ();
  }
}

=begin comment

use IPC::Open2;
use Encode;

sub diffstat {
  my ($log) = @_;
  my $item = 'Git::Repository::Log::Numstat::Item';
  my @numstat;

  my %from = (); my $re_rename = qr/(?:rename|copy)/;
  for (split /diff --git [^\n]+\n/, $log->extra) {
    if (/
          similarity \s index \s \d+\%    \n
          $re_rename \s from  \s ([^\n]+) \n
          $re_rename \s to    \s ([^\n]+) \n
        /xs) {
      $from{$2} = $1;
    }
  }
  my $pid = open2(my $diffstat, my $diff, qw/diffstat -p1 -f0/);
  if (my $enc = $iterator->encoding) {
    binmode $_, ":$enc" for $diff, $diffstat;
  }
  print $diff $log->extra;
  close $diff;
  while (<$diffstat>) {
    chop;
    next unless my ($path, $added, $deleted, $changed) =
      /^
       \s* ([^\|\s]+) \s* \|    # path
       \s*  \d+                 # total
       \s* (\d+) \s* \+         # added
       \s* (\d+) \s* \-         # deleted
       \s* (\d+) \s* \!         # changed
      /x;
    if (my $from = $from{$path}) {
      push @numstat, $class->_numstat(
        $added + $changed, $deleted + $changed, $from, $path
       );
      delete $from{$path}
    } else {
      push @numstat, $class->_numstat(
        $added + $changed, $deleted + $changed, $path
       );
    }
  }
  for (keys %from) {
    push @numstat, $class->_numstat(
      0, 0, $from{$_}, $_
     );
  }
  close $diffstat;
  waitpid($pid, 0);
  $log->{numstat} = \@numstat;
  @numstat;
}

=end comment

=cut

1;

# ABSTRACT: Class representing git log --numstat data

=pod

=head1 SYNOPSIS

    # load the LogNumstat plugin
    use Git::Repository 'LogNumstat';

    # get the log --numstat for last commit
    my ($log) = Git::Repository->log_numstat( '-1' );

    # get the author's email
    print my $email = $log->author_email;  # see Git::Repository::Log

    # get the numstat from extra log
    for ($log->numstat) {
        print join "\t" => $_->added => $_->deleted
            => join(" => ", $_->path), "\n";
    }

=head1 DESCRIPTION

L<Git::Repository::LogNumstat> is a class whose instances represent
log items from a B<git log --numstat> stream.

=head1 CONSTRUCTOR

This method shouldn't be used directly. L<Git::Repository::LogNumstat::Iterator>
should be the preferred way to create L<Git::Repository::LogNumstat> objects.

=head2 new

Create a new L<Git::Repository::LogNumstat> instance, using the list of key/values
passed as parameters. The supported keys are (from the output of
C<git log --numstat --pretty=raw>):

=over 4

=item numstat

=item added, deleted, path

=back

=head1 COPYRIGHT

Copyright 2015 Kubo Koich, all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
