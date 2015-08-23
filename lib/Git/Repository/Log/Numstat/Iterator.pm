package Git::Repository::Log::Numstat::Iterator;

use strict;
use warnings;
use 5.006;

use Git::Repository::Log::Iterator;
our @ISA = qw( Git::Repository::Log::Iterator );

use Git::Repository::Log::Numstat;
*VERSION = \$Git::Repository::Plugin::Log::Numstat::VERSION;

sub next {
  my $self = shift;
  return unless my $log = $self->SUPER::next(@_);
  bless $log, 'Git::Repository::Log::Numstat';
}

1;

# ABSTRACT: Split a git log --numstat stream into records

=pod

=head1 SYNOPSIS

    use Git::Repository::NumStat::Iterator;

    # use a default Git::Repository context
    my $iter = Git::Repository::NumStat::Iterator->new('HEAD~10..');

    # or provide an existing instance
    my $iter = Git::Repository::NumStat::Iterator->new( $r, 'HEAD~10..' );

    # get the next numstat record
    while ( my $numstat = $iter->next ) {
        ...;
    }

=head1 DESCRIPTION

L<Git::Repository::NumStat::Iterator> initiates a B<git log --numstat>
command from a list of paramaters and parses its output to produce
L<Git::Repository::NumStat> objects represening each log and numstat item.

=head1 METHODS

=head2 new

    my $iter = Git::Repository::NumStat::Iterator->new( @args );

=head2 next

    my $numstat = $iter->next;

Return the next numstat item as a L<Git::Repository::NumStat> object,
or nothing if the stream has ended.

=head1 COPYRIGHT

Copyright 2015 Kubo Koichi, all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
