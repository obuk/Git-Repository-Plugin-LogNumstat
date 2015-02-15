package Git::Repository::Plugin::LogNumstat;

use warnings;
use strict;
use 5.006;

our $VERSION = '0.02';

use Git::Repository::Plugin;
our @ISA = qw( Git::Repository::Plugin );
sub _keywords { qw( log_numstat ) }

use Git::Repository::LogNumstat::Iterator;

sub log_numstat {

    # skip the invocant when invoked as a class method
    shift if !ref $_[0];

    # get the iterator
    my $iter = Git::Repository::LogNumstat::Iterator->new(@_);

    # scalar context: return the iterator
    return $iter if !wantarray;

    # list context: return all Git::Repository::LogNumstat objects
    my @log_numstats;
    while ( my $log_numstat = $iter->next ) {
        push @log_numstats, $log_numstat;
    }
    return @log_numstats;
}

1;

# ABSTRACT: Add a log_numstat() method to Git::Repository

=pod

=head1 NAME

Git::Repository::Plugin::LogNumstat - Class representing git log --numstat data

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

   # all Git::Repository::LogNumstat objects obtained from the log
   my @logs = $r->log_numstat( @args );

Run C<git log --numstat> with the given arguments.

=head1 SEE ALSO

L<Git::Repository::Plugin>,
L<Git::Repository::LogNumstat::Iterator>,
L<Git::Repository::LogNumstat>.

=head1 COPYRIGHT

Copyright 2015 Kubo Koich, all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
