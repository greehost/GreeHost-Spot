package GreeHost::Spot::Model::DB;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model::DBIC::Schema';

$ENV{DBIX_CONFIG_DIR}  = '/opt/catalyst/';
$ENV{IS_RUNNING_TESTS} = 0 unless defined $ENV{IS_RUNNING_TESTS};

my @connect_info = $ENV{IS_RUNNING_TESTS} == 1
    ? ( $ENV{PSQL_TEST_DB_DSN} )
    : $ENV{'TCL_USE_ENV_DB'}
        ? ( $ENV{DB_DSN}, $ENV{DB_USER}, $ENV{DB_PASS} )
        : ( 'SPOT_DB' );

__PACKAGE__->config(
    schema_class => 'GreeHost::Spot::DB',
    connect_info => [ @connect_info ],
);

__PACKAGE__->meta->make_immutable;

