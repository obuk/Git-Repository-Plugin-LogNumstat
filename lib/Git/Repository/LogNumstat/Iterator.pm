package Git::Repository::LogNumstat::Iterator;

use strict;
use warnings;
use 5.006;

use Git::Repository::Log::Iterator;
our @ISA = qw( Git::Repository::Log::Iterator );

use Git::Repository::LogNumstat;
*VERSION = \$Git::Repository::Plugin::LogNumstat::VERSION;

sub new {
  my $class = shift;
  my @opt = grep /^--(diffstat|numstat)$/, @_;
  my ($reverse) = grep /^--reverse$/, @_;
  my @cmd = ((@opt && $opt[-1] eq '--diffstat'? '-p' : '--numstat'),
             grep !/^--(diffstat|numstat)$/, @_);
  my $self = $class->SUPER::new(@cmd);
  $self->{_numstat} = $cmd[0] eq '--numstat';
  $self->{_reverse} = $reverse;
  $self;
}

sub next {
  my $self = shift;
  return unless my $log = $self->SUPER::next(@_);
  $log->{numstat} = [Git::Repository::LogNumstat->new($self, $log)];
  $log;
}

1;

# ABSTRACT: Split a git log --numstat stream into records

=pod

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
