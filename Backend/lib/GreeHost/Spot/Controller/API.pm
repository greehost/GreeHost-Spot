package GreeHost::Spot::Controller::API;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }


sub base :Chained('/') PathPart('api') CaptureArgs(0) {
    my ( $self, $c ) = @_;


    # Allow web browsers to access the API.
    $c->res->header( 'Access-Control-Allow-Origin'      => $c->req->header( 'origin' ) );
    $c->res->header( 'Access-Control-Allow-Credentials' => 'true' );
}

__PACKAGE__->meta->make_immutable;
