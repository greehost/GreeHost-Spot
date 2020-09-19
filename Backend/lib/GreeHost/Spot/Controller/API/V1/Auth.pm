package GreeHost::Spot::Controller::API::V1::Auth;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub insecure :Chained( '/api/v1/insecure' ) PathPart('auth') CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub forgot :Chained('insecure') PathPart('forgot') Method('POST') Args(0) {
    my ( $self, $c ) = @_;
    my $email_address = $c->req->body_data->{'email_address'};

    # Handle forgot password:
    # 1. Accept an email addresss.
    # 2. Lookup the email address and see if there is an account.
    #     1. If there is an account:
    #         1. add a reset auth token to the account
    #         2. send an email with the auth token to the user's email addresss
    #         3. return success
    #     2. If there is no account:
    #         1. Return an error (User expectation over info leak, the info leak would happen with our sign up process anyway)

}

sub login :Chained('insecure') PathPart('login') Method('POST') Args(0) {
    my ( $self, $c ) = @_;

    my $payload = $c->process_body_data(
        email    => [qw( defined )],
        password => [qw( defined minlength=8 )],
    );

    $c->model('DB')->resultset('AuthPassword')->known_email( $payload->{email} )
        or $c->detach( '/api/v1/error', [ 'Unknown username or password.', 403 ] );

    my $user = $c->model('DB')->resultset('Person')->find( { email => $payload->{email} } );

    $c->detach( '/api/v1/error', [ 'Unknown username or password.', 403 ] )
        unless $user->auth_password->check_password( $payload->{password} );

    $c->session->{uid} = $user->id;
}

__PACKAGE__->meta->make_immutable;
