package Dancer::Session::PSGI;

use strict;
use warnings;
our $VERSION = '0.01';

use Dancer::SharedData;
use base 'Dancer::Session::Abstract';

sub retrieve {
    my ($class, $id) = @_;
    my $req = Plack::Request->new(Dancer::SharedData->request->{env});
    my $session = $req->session();
    return Dancer::Session::PSGI->new(%$session);
}

sub flush {
    my $self = shift;
    my $req = Plack::Request->new(Dancer::SharedData->request->{env});
    my $session = $req->session();
    map {$session->{$_} = $self->{$_}} keys %$self;
    return $self;
}

1;
__END__

=head1 NAME

Dancer::Session::PSGI - Let Plack::Middleware::Session handle session

=head1 SYNOPSIS

    setting session => 'PSGI'

=head1 DESCRIPTION

Dancer::Session::PSGI let you use C<Plack::Middleware::Session> as backend for your sessions.

=head1 AUTHOR

franck cuny E<lt>franck@lumberjaph.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
