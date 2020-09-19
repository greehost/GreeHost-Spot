package GreeHost::Spot::Controller::API::V1;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub secure :Chained('/api/base') PathPart('v1') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->detach( '/api/v1/error', [ "Not Authorized", 403 ] )
        unless defined $c->session->{uid};

    my $user = $c->model('DB')->resultset('Person')->find( { id => $c->session->{uid} } );

    $c->detach( '/api/v1/error', [ "Not Authorized", 403 ] )
        unless ( defined $user and $user->is_enabled );
        
    # We have a valid user account.
    $c->stash->{user} = $user;

    # Default to successful status, ->error() will set to 0 automatically.
    $c->stash->{json}->{status} = 1; 
}

sub insecure :Chained('/api/base') PathPart('v1') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    
    $c->stash->{json}->{status} = 1;

}

sub error :Private {
    my ( $self, $c, $error, $code ) = @_;

    $c->res->code( $code || 500 );

    $c->stash->{json} = {
        status => 0,
        ( ref $error eq 'HASH'
            ? ( %$error )
            : ( $error ? ( error => $error ) : ( error => "Unknown error" ) )
        ),
    };
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf8

=head1 NAME

GreeHost::Spot::Controller::API::V1

=head1 Description

This module provides the base chains and error reporting for
Spot, the 'Single Point Of Truth.'

=head1 Chains

=head2 secure
This method should be the chain point for any secure API calls,
a secure API call is one in which a user account is loaded and
verified.

Usage:

:Chained('/api/v1/secure') ...

=head2 insecure
This method should be the chain point for any insecure API calls,
an insecure API call is one in which we do not have a user account
loaded, for example password forget / user login api calls will not
have a known user when they're invoked.

Usage:

:Chained('/api/v1/insecure') ...


=head2 error
This method should be used to throw any error from the API.

Usage:
    $c->detach( '/api/v1/error', [ 'My error' ] );
        -> { status => 0, error => 'My error' } -> HTTP Code 500

    $c->detach( '/api/v1/error', [ 'My error', 404 ] );
        -> { status => 0, error => 'My error' } -> HTTP Code 404

    $c->detach( '/api/v1/error', [ { magic_error => 'My error' } ] );
        -> { status => 0, magic_error => 'My error' } -> HTTP Code 500

    $c->detach( '/api/v1/error', [ { error => 'My error', status => -1 } ] );
        -> { status => -1, error => 'My error' } -> HTTP Code 500

