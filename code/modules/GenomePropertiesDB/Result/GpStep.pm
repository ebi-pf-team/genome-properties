use utf8;
package GenomePropertiesDB::Result::GpStep;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GenomePropertiesDB::Result::GpStep

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<gp_step>

=cut

__PACKAGE__->table("gp_step");

=head1 ACCESSORS

=head2 gp_accession

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 11

=head2 auto_step

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 step_number

  data_type: 'integer'
  is_nullable: 0

=head2 step_id

  data_type: 'varchar'
  is_nullable: 0
  size: 75

=head2 step_display_name

  data_type: 'varchar'
  is_nullable: 1
  size: 75

=head2 required

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "gp_accession",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 11 },
  "auto_step",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "step_number",
  { data_type => "integer", is_nullable => 0 },
  "step_id",
  { data_type => "varchar", is_nullable => 0, size => 75 },
  "step_display_name",
  { data_type => "varchar", is_nullable => 1, size => 75 },
  "required",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</auto_step>

=back

=cut

__PACKAGE__->set_primary_key("auto_step");

=head1 RELATIONS

=head2 gp_accession

Type: belongs_to

Related object: L<GenomePropertiesDB::Result::GenomeProperty>

=cut

__PACKAGE__->belongs_to(
  "gp_accession",
  "GenomePropertiesDB::Result::GenomeProperty",
  { accession => "gp_accession" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 gp_step_evidence_gps

Type: has_many

Related object: L<GenomePropertiesDB::Result::GpStepEvidenceGp>

=cut

__PACKAGE__->has_many(
  "gp_step_evidence_gps",
  "GenomePropertiesDB::Result::GpStepEvidenceGp",
  { "foreign.auto_step" => "self.auto_step" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gp_step_evidence_iprs

Type: has_many

Related object: L<GenomePropertiesDB::Result::GpStepEvidenceIpr>

=cut

__PACKAGE__->has_many(
  "gp_step_evidence_iprs",
  "GenomePropertiesDB::Result::GpStepEvidenceIpr",
  { "foreign.auto_step" => "self.auto_step" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-07-08 14:51:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0FMemM4M0/zZzIDBtkU9EA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
