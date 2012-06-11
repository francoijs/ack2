package App::Ack::Resources;

use App::Ack;

use File::Next;

use warnings;
use strict;

=head1 SYNOPSIS

This is the base class for App::Ack::Resources, an iterator factory
for App::Ack::Resource objects.

=head1 METHODS

=head2 from_argv( \%opt, \@starting_points )

Return an iterator that does the file finding for us.

=cut

sub from_argv {
    my $class = shift;
    my $opt   = shift;
    my $start = shift;

    my $self = bless {}, $class;

    my $file_filter    = undef;
    my $descend_filter = undef;

    $self->{iter} =
        File::Next::files( {
            file_filter     => $opt->{file_filter},
            descend_filter  => $opt->{descend_filter},
            error_handler   => sub { my $msg = shift; App::Ack::warn( $msg ) },
            sort_files      => $opt->{sort_files},
            follow_symlinks => $opt->{follow},
        }, @{$start} );

    return $self;
}

=head2 from_file( \%opt, $filename )

Return an iterator that reads the list of files to search from a
given file.  If I<$filename> is '-', then it reads from STDIN.

=cut

sub from_file {
    my $class = shift;
    my $opt   = shift;
    my $file  = shift;

    my $iter =
        File::Next::from_file( {
            error_handler => sub { my $msg = shift; App::Ack::warn( $msg ) },
            sort_files    => $opt->{sort_files},
        }, $file ) or return undef;

    return bless {
        iter => $iter,
    }, $class;
}

# This is for reading input lines from STDIN, not the list of files from STDIN
sub from_stdin {
    my $class = shift;
    my $opt   = shift;

    my $self  = bless {}, $class;

    my $has_been_called = 0;

    $self->{iter} = sub {
        if ( !$has_been_called ) {
            $has_been_called = 1;
            return '-';
        }
        return;
    };

    return $self;
}

sub next {
    my $self = shift;

    my $file = $self->{iter}->() or return;

    return App::Ack::Resource::Basic->new( $file );
}

1;
