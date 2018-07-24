use utf8;
package GenomePropertiesDB::Result::GenomeProperty;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GenomePropertiesDB::Result::GenomeProperty

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<genome_property>

=cut

__PACKAGE__->table("genome_property");

=head1 ACCESSORS

=head2 accession

  data_type: 'varchar'
  is_nullable: 0
  size: 11

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 30

=head2 author

  data_type: 'text'
  is_nullable: 0

=head2 threshold

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 private

  data_type: 'text'
  is_nullable: 1

=head2 ispublic

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 checked

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "accession",
  { data_type => "varchar", is_nullable => 0, size => 11 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 30 },
  "author",
  { data_type => "text", is_nullable => 0 },
  "threshold",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "private",
  { data_type => "text", is_nullable => 1 },
  "ispublic",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "checked",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</accession>

=back

=cut

__PACKAGE__->set_primary_key("accession");

=head1 RELATIONS

=head2 gp_database_links

Type: has_many

Related object: L<GenomePropertiesDB::Result::GpDatabaseLink>

=cut

__PACKAGE__->has_many(
  "gp_database_links",
  "GenomePropertiesDB::Result::GpDatabaseLink",
  { "foreign.gp_accession" => "self.accession" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gp_lit_refs

Type: has_many

Related object: L<GenomePropertiesDB::Result::GpLitRef>

=cut

__PACKAGE__->has_many(
  "gp_lit_refs",
  "GenomePropertiesDB::Result::GpLitRef",
  { "foreign.gp_accession" => "self.accession" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gp_step_evidence_gps

Type: has_many

Related object: L<GenomePropertiesDB::Result::GpStepEvidenceGp>

=cut

__PACKAGE__->has_many(
  "gp_step_evidence_gps",
  "GenomePropertiesDB::Result::GpStepEvidenceGp",
  { "foreign.gp_accession" => "self.accession" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gp_steps

Type: has_many

Related object: L<GenomePropertiesDB::Result::GpStep>

=cut

__PACKAGE__->has_many(
  "gp_steps",
  "GenomePropertiesDB::Result::GpStep",
  { "foreign.gp_accession" => "self.accession" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-07-20 12:10:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7ku7Ybz9mG7tWzoRUk618g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
