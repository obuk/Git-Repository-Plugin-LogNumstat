package Git::Repository::Plugin::Log::Numstat;

use warnings;
use strict;
use 5.006;

our $VERSION = '0.05_01';

use Git::Repository qw(Log);
use Git::Repository::Plugin;
our @ISA      = qw( Git::Repository::Plugin );
sub _keywords { qw( log_numstat ) }

use Git::Repository::Log::Numstat::Iterator;

use Hook::WrapSub qw( wrap_subs unwrap_subs );

wrap_subs
  sub {
  },
  'Git::Repository::Log::Iterator::new',
  sub {
    my ($class, @cmd) = @_;
    my $numstat;
    for (@cmd) {
      $numstat = 0 if /^--no-numstat$/;
      $numstat = 1 if /^--numstat$/;
      last         if /^--$/;
    }
    my ($self) = @Hook::WrapSub::result;
    $self->{numstat} = $numstat;
  };

wrap_subs
  sub {
  },
  'Git::Repository::Log::Iterator::next',
  sub {
    my ($self) = @_;
    for (grep { ref $_ } @Hook::WrapSub::result) {
      $_->{_numstat} = $self->{numstat};
    }
  };

{
  no strict 'refs';
  my $attr = "Git::Repository::Log::numstat";
  *$attr = \&Git::Repository::Log::Numstat::numstat;
}


sub log_numstat {
  my $r = shift;
  $r->log('--numstat', @_);
}

1;

=pod

=head1 NAME

Git::Repository::Plugin::Log::Numstat - Class representing git log --numstat data

=head1 SYNOPSIS

    # load the plugin
    use Git::Repository 'LogNumStat';

    my $r = Git::Repository->new();

    # get all log and numstat objects
    my @logs = $r->log_numstat(qw( --since=yesterday ));

    # get an iterator
    my $iter = $r->log_numstat(qw( --since=yesterday ));
    while ( my $log = $iter->next() ) {
        ...;
    }

=head1 DESCRIPTION

This module adds a new method to L<Git::Repository::Log>.

=head1 METHOD

=head2 log_numstat

   # iterator
   my $iter = $r->log_numstat( @args );

   # all Git::Repository::Log::Numstat objects obtained from the log
   my @logs = $r->log_numstat( @args );

Run C<git log --numstat> with the given arguments.

=head1 SEE ALSO

L<Git::Repository::Plugin>,
L<Git::Repository::Log::Numstat::Iterator>,
L<Git::Repository::Log::Numstat>.

=head1 COPYRIGHT

Copyright 2015 Kubo Koich, all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
