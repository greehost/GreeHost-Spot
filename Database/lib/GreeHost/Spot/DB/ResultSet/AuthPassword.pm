package GreeHost::Spot::DB::ResultSet::AuthPassword;
use warnings;
use strict;
use base 'DBIx::Class::ResultSet';

sub known_email {
    my ( $self, $email ) = @_;

    my $count = $self->search(
        { 'person.email' => $email },
        { join => 'person' }
    )->count;

    return 1 if $count >= 1;
    return "";
}

1;
