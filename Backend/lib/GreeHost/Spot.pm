package GreeHost::Spot;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    GreeHost
    Session
    Session::Store::Cookie
    Session::State::Cookie
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in greehost_spot.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name                                        => 'GreeHost::Spot',
    disable_component_resolution_regex_fallback => 1,       # Disable deprecated behavior.
    enable_catalyst_header                      => 1,       # Send X-Catalyst header
    encoding                                    => 'UTF-8', # Setup request decoding and response encoding
    default_view                                => 'JSON',
);

__PACKAGE__->config(
    'View::JSON' => {
        expose_stash => 'json',
    },
);

__PACKAGE__->config(
    'Plugin::Session' => {
        cookie_name            => 'session_id',
        storage_cookie_name    => 'session_data',
        storage_cookie_expires => '+30d',
        storage_secret_key     => 'YourSecretKeyDontShareWithAnybody',
    },
);

__PACKAGE__->setup();
