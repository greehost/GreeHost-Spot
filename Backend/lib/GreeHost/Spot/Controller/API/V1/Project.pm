package GreeHost::Spot::Controller::API::V1::Project;
use Moose;
use namespace::autoclean;
use Scalar::Util qw( looks_like_number );
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller'; }

sub secure_base :Chained('/api/v1/secure') PathPart('project') CaptureArgs(0) {
    my ( $self, $c, $user_id ) = @_;
}

sub create_project :Chained('secure_base') PathPart('') Method('POST') Args(0) {
    my ( $self, $c ) = @_;

    my $payload = $c->process_body_data(
        name        => [qw( defined )],
        description => [qw( defined )],
        repository  => [qw( defined )],
        ssh_key     => [qw( defined )],
    );
    
    my $project = try {
        $c->model('DB')->schema->txn_do(sub {
            $c->stash->{user}->create_related('projects', {
                name        => $payload->{name},
                description => $payload->{description},
                repository  => $payload->{repository},
                ssh_key     => $payload->{ssh_key},
            });
        });
    } catch {
        $c->detach('/api/v1/error', [ "Error creating project: $_" ] );
    };
}

sub list_project :Chained('secure_base') PathPart('') Method('GET') Args(0) {
    my ( $self, $c ) = @_;
    
    my $rs = $c->stash->{user}->search_related('projects');

    while ( my $record = $rs->next ) {
        $c->stash->{json}->{project}->{$record->name} = {
            name        => $record->name,
            description => $record->description,
            repository  => $record->repository,
        };
    }
}

1;
