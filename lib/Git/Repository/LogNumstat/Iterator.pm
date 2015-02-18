package Git::Repository::LogNumstat::Iterator;

use strict;
use warnings;
use 5.006;
use Carp;

use Git::Repository::Log::Iterator;
our @ISA = qw( Git::Repository::Log::Iterator );

use Git::Repository::LogNumstat;
*VERSION = \$Git::Repository::Plugin::LogNumstat::VERSION;

sub new {
  my $class = shift;
  my @git = @_ && ref $_[0] && shift || ();
  my $enc = @_ && $_[0] =~ /^:/ && shift || '';
  my $numstat = qw/--numstat/;
  my @opt = ();
  while (my $opt = shift) {
    if ($opt eq '--') {
      unshift @_, $opt;
      last;
    } elsif ($opt eq '--numstat') {
      $numstat = $opt;
    } elsif ($opt eq '--diffstat') {
      $numstat = '-p';
    } else {
      push @opt, $opt;
    }
  }
  my @badopt = grep /^--(dir|short|patch-with-)?stat$/, @opt;
  croak "log_numstat() cannot handle @badopt" if @badopt;
  my $self = $class->SUPER::new(@git, @opt, $numstat, @_);
  $self->{numstat} = $numstat eq '--numstat';
  $self->encoding($enc) if $enc;
  $self;
}

sub encoding {
  my $self = shift;
  if (@_) {
    ($self->{encoding} = shift) =~ s/^://;
    binmode $self->{fh}, ":$self->{encoding}";
  } else {
    $self->{encoding};
  }
}

sub next {
  my $self = shift;
  return unless my $log = $self->SUPER::next(@_);
  $log->{numstat} = undef;
  $log->{numstat} = [Git::Repository::LogNumstat->new($self, $log)];
  $log;
}

1;

=pod

=head1 NAME

Git::Repository::LogNumstat::Iterator - Split a git log --numstat stream into records

=head1 SYNOPSIS

    use Git::Repository::LogNumstat::Iterator;

    # use a default Git::Repository context
    my $iter = Git::Repository::LogNumstat::Iterator->new('HEAD~10..');

    # or provide an existing instance
    my $iter = Git::Repository::LogNumstat::Iterator->new( $r, 'HEAD~10..' );

    # get the next numstat record
    while ( my $numstat = $iter->next ) {
        ...;
    }

=head1 DESCRIPTION

L<Git::Repository::LogNumstat::Iterator> initiates a B<git log --numstat>
command from a list of paramaters and parses its output to produce
L<Git::Repository::LogNumstat> objects represening each log and numstat item.

=head1 METHODS

=head2 new

    my $iter = Git::Repository::LogNumstat::Iterator->new( @args );

=head2 encoding

    $iter->encoding('utf8');

=head2 next

    my $log = $iter->next;

Return the next log_numstat item as a L<Git::Repository::LogNumstat> object,
or nothing if the stream has ended.

=head1 COPYRIGHT

Copyright 2015 Kubo Koichi, all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
