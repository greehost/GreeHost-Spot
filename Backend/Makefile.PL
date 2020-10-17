#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use lib '.';
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'GreeHost-Spot';
all_from 'lib/GreeHost/Spot.pm';

requires 'Catalyst::Runtime' => '5.90126';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats




# Custom Requires 
requires 'Catalyst::View::JSON';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Test::Postgresql58';
requires 'Import::Into';
requires 'Object::Tap';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::Store::Cookie';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'DateTime::TimeZone';

# Default test requires
test_requires 'Test::More' => '0.88';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
