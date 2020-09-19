package GreeHost::Spot::Controller::API::V1::SSLStore;
use Moose;
use namespace::autoclean;
use Scalar::Util qw( looks_like_number );
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller'; }

sub secure_base :Chained('/api/v1/secure') PathPart('sslstore') CaptureArgs(0) {
    my ( $self, $c, $user_id ) = @_;
}

sub create_certificate :Chained('secure_base') PathPart('') Method('POST') Args(0) {
    my ( $self, $c ) = @_;

    my $payload = $c->process_body_data(
        name        => [qw( defined )],
        domains      => [qw(  )],
        provider    => [qw( defined )],
        credentials => [qw(  )],
    );
    
    my $provider = $c->model('DB')->resultset('SslStoreProvider')->search( { name => $payload->{provider} } )->first
        or $c->detach('/api/v1/error', [ 'Error: Invalid SSL Provider.' ]);

    my $cert = try {

        $c->model('DB')->schema->txn_do(sub {
            $c->stash->{user}->create_related('ssl_stores', {
                name        => $payload->{name},
                domains     => $payload->{domains},
                provider    => $provider,
                credentials => $payload->{credentials},
            });
        });
    } catch {
        $c->detach('/api/v1/error', [ "Error creating certificate: $_" ] );
    };

    $c->stash->{json} = {
        status  => 1,
    };
}

sub list_certificates :Chained('secure_base') PathPart('') Method('GET') Args(0) {
    my ( $self, $c ) = @_;

    my $rs = $c->stash->{user}->search_related('ssl_stores');

    while ( my $record = $rs->next ) {
        $c->stash->{json}->{store}->{$record->name} = {
            name     => $record->name,
            domains  => $record->domains,
            provider => $record->provider->name,
        };
    }
}

__PACKAGE__->meta->make_immutable;
