package Dancer::Session::PSGI;

#
# ABSTRACT: Let Plack::Middleware::Session handle Dancer's session
#
# Dancer makes this a bit difficult, as it's Session engine assumes
# that it is dealing with creating and managing the session cookie,
# which isn't the case.
#

use strict;
use warnings;
our $VERSION = '0.01';

use Dancer::SharedData;
use base 'Dancer::Session::Abstract';

#
# Override the default behavior from Dancer::Session::Abstract
# (setting a new Session ID) as Plack::Middleware::Session
# deals with that.
#
sub init { }

#
# Plack::Middleware::Session has already extracted the cookie data and 
# created an object (with an ID) and so our retrieve doesn't need the ID.
# However, we return a dummy ID value so that Dancer::Session->get_current_session
# will call our retrieve instead of creating a new object.
#
sub read_session_id {
    return 1;
}

#
# Plack::Middleware::Session handles creating the cookie from the session
# data, so skip that step by overriding Dancer::Abstract->write_session_id
#
sub write_session_id {
    return 1;
}

#
# Return a Dancer::Session::PSGI object that contains a copy of all
# the values in the Plack::Middleware::Session
#
sub retrieve {
    my ($class, $id) = @_;
    my $session = Dancer::SharedData->request->{env}->{'psgix.session'};
    return Dancer::Session::PSGI->new(%$session);
}

#
# Copy the values form the local Dancer::Session::PSGI object back into
# the values in the Plack::Middleware::Session
#
sub flush {
    my $self = shift;
    my $session = Dancer::SharedData->request->{env}->{'psgix.session'};
    foreach ( keys %$self ) {
        if ( defined($self->{$_}) ) {
            $session->{$_} = $self->{$_};
        } else {
            delete $self->{$_};
            delete $session->{$_};
        }
    }
    return $self;
}

#
# Completely remove the session
#
sub destroy {
    my $self = shift;
    my $session = Dancer::SharedData->request->{env}->{'psgix.session'};
    delete $session->{$_} for keys %$session;
    my $session_options = Dancer::SharedData->request->{env}->{'psgix.session.options'};
    $session_options->{expire} = 1;
}

1;

=head1 SYNOPSIS

A basic psgi application

    use strict; use warnings;
    use Plack::Builder;

    my $app = sub {
        my $session = (shift)->{'psgix.session'};
        return [
            200,
            [ 'Content-Type' => 'text/plain' ],
            [ "Hello, you've been here for ", $session->{counter}++, "th time!" ],
        ];
    };

    builder { enable 'Session', store => 'File'; $app; };

In your app.psgi:

    builder {
        enable "Session", store => "File";
        sub { my $env = shift; my $request = Dancer::Request->new($env); Dancer->dance($request);};
    };

And a simple Dancer application:

   package session;
   use Dancer ':syntax';

    get '/' => sub {
        my $count = session("counter");
        session "counter" => ++$count;
        template 'index', {count => $count};
    };

Now, your two applications can share the same session informations.

=head1 DESCRIPTION

Dancer::Session::PSGI let you use C<Plack::Middleware::Session> as backend for your sessions.
