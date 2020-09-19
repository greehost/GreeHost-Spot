package GreeHost::Spot::Controller::API::V1::User;
use Moose;
use namespace::autoclean;
use Scalar::Util qw( looks_like_number );
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller'; }

sub insecure :Chained('/api/v1/insecure') PathPart('user') CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub secure :Chained('/api/v1/secure') PathPart('user') CaptureArgs(1) {
    my ( $self, $c, $user_id ) = @_;

    if ( $user_id eq '~' ) {
        return; # Logged in user is targetting the logged in user.
    }
}

sub create_account :Chained('insecure') PathPart('') Method('POST') Args(0) {
    my ( $self, $c ) = @_;

    my $payload = $c->process_body_data(
        name     => [qw( defined )],
        email    => [qw( defined )],
        password => [qw( defined minlength=8 )],
    );

    # Create the user account and the settings!
    # TODO: Add email address confirmation as a required thing.
    my $person = try {
        $c->model('DB')->schema->txn_do(sub {
            my $person = $c->model('DB')->resultset('Person')->create({
                email => $payload->{email},
                name  => $payload->{name},
            });
            $person->new_related( 'auth_password', {})->set_password( $payload->{password} );
            return $person;
        });
    } catch {
        # TODO: Reporting DB errors to me at this stage is important.
        $c->detach('/api/v1/error', [ "Error creating account: $_" ] );
    };

    $c->stash->{json} = {
        status => 1,
        person => {
            name     => $person->name,
            email    => $person->email,
            uid      => $person->id,
        }
    };
}

sub view_account :Chained('secure') PathPart('') Method('GET') Args(0) {
    my ( $self, $c ) = @_;

    my $person = $c->stash->{user};

    $c->stash->{json} = {
        status => 1,
        person => {
            name     => $person->name,
            email    => $person->email,
            uid      => $person->id,
        },
    };
}

__PACKAGE__->meta->make_immutable;
