use utf8;
package GenomePropertiesDB::Result::IprStepToGo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GenomePropertiesDB::Result::IprStepToGo

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ipr_step_to_go>

=cut

__PACKAGE__->table("ipr_step_to_go");

=head1 ACCESSORS

=head2 auto_ipr_step

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 go_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 10

=cut

__PACKAGE__->add_columns(
  "auto_ipr_step",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "go_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 10 },
);

=head1 RELATIONS

=head2 auto_ipr_step

Type: belongs_to

Related object: L<GenomePropertiesDB::Result::GpStepEvidenceIpr>

=cut

__PACKAGE__->belongs_to(
  "auto_ipr_step",
  "GenomePropertiesDB::Result::GpStepEvidenceIpr",
  { auto_ipr_step => "auto_ipr_step" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 go

Type: belongs_to

Related object: L<GenomePropertiesDB::Result::GoTerm>

=cut

__PACKAGE__->belongs_to(
  "go",
  "GenomePropertiesDB::Result::GoTerm",
  { go_id => "go_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-07-23 10:17:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/MDiYQMx8PHaWR3/qfcjQQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
