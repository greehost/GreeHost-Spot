use utf8;
package GreeHost::Spot::DB::Result::SslStore;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GreeHost::Spot::DB::Result::SslStore

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::InflateColumn::Serializer>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "InflateColumn::Serializer");

=head1 TABLE: C<ssl_store>

=cut

__PACKAGE__->table("ssl_store");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'ssl_store_id_seq'

=head2 owner_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 domains

  data_type: 'text[]'
  default_value: '{}'::text[]
  is_nullable: 0

=head2 provider_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 credentials

  data_type: 'json'
  default_value: '{}'
  is_nullable: 0
  serializer_class: 'JSON'

=head2 created_at

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "ssl_store_id_seq",
  },
  "owner_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "domains",
  {
    data_type     => "text[]",
    default_value => \"'{}'::text[]",
    is_nullable   => 0,
  },
  "provider_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "credentials",
  {
    data_type        => "json",
    default_value    => "{}",
    is_nullable      => 0,
    serializer_class => "JSON",
  },
  "created_at",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 owner

Type: belongs_to

Related object: L<GreeHost::Spot::DB::Result::Person>

=cut

__PACKAGE__->belongs_to(
  "owner",
  "GreeHost::Spot::DB::Result::Person",
  { id => "owner_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 provider

Type: belongs_to

Related object: L<GreeHost::Spot::DB::Result::SslStoreProvider>

=cut

__PACKAGE__->belongs_to(
  "provider",
  "GreeHost::Spot::DB::Result::SslStoreProvider",
  { id => "provider_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-09-12 12:44:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:var7pKRifYZQcrdF7s0NDg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
