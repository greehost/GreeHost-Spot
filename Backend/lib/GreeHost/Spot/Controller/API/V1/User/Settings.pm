package GreeHost::Spot::Controller::API::V1::User::Settings;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub secure :Chained('/api/v1/user/secure') PathPart('settings') CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

# Function for GET /api/v1/user/:id/settings
#
# Usage:
#     GET /api/v1/user/~/settings                   - Get all settings
#     GET /api/v1/user/~/settings?name=bar          - Get setting named 'bar'
#     GET /api/v1/user/~/settings?name=bar&name=baz - Get setting named 'bar' and 'baz'
#
# Returns settings for the loggined in user (~) or a user the logged in user is authorized for (:id).
#
# This function should be expected to return an HTTP 200.
#
# When called without name argument, settings are returned in a structure that looks like:
#
#     {
#         status => 1,
#         settings => {
#             setting_name => setting_value,
#             ...,
#         }
#     }
#
# When called with one or more name arguments, settings are returned in a structure that looks like:
#
#     {
#         status => 1,
#         setting_name => setting_value,
#         ...,
#     }
sub get_settings :Chained('secure') PathPart('') Method('GET') Args(0) {
    my ( $self, $c ) = @_;

    # If we do not have a name query parameter, we're going to just dump all of the user's settings
    if ( not exists $c->req->query_params->{name} ) {
        $c->stash->{json}->{settings} = $c->stash->{user}->get_settings;
        $c->detach;
    }

    # name can be an array ref (ex /settings?name=foo&name=bar) or a single scalar.
    my $settings = $c->req->query_params->{name};
    foreach my $setting ( ref $settings ? @{$settings} : $settings ) {
        defined( $c->stash->{json}->{$setting} = $c->stash->{user}->setting($setting) )
            or $c->detach( '/api/v1/error', [ "Unknown setting $setting" ] );
    }
}


# Function for POST /api/v1/user/:id/settings
#
# Usage:
#     POST /api/v1/user/~/settings
#         [X] JSON Payload
#         [X] JSON Headers
#
# JSON Payload:
#
#     settings => {
#         name       => value,
#         other_name => [ ... ],
#         final_name => { ... },
#         ...,
#     }
#
#     name: Should be an alphanumeric key.
#     value: may be a simple scalar, an array, or a hash onto itself.
#
# This function should be expected to return an HTTP 200 status, and a JSON
# payload of { status => 1 }.
#
sub post_settings :Chained('secure') PathPart('') Method('POST') Args(0) {
    my ( $self, $c ) = @_;

    my $settings = $c->req->body_data->{settings};

    foreach my $setting ( keys %{$settings} ) {
        $c->stash->{user}->setting( $setting => $settings->{$setting} );
    }
}

__PACKAGE__->meta->make_immutable;

