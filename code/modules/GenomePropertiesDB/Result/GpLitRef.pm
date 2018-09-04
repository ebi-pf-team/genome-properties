use utf8;
package GenomePropertiesDB::Result::GpLitRef;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GenomePropertiesDB::Result::GpLitRef

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<gp_lit_ref>

=cut

__PACKAGE__->table("gp_lit_ref");

=head1 ACCESSORS

=head2 gp_accession

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 11

=head2 literature_reference_pmid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 list_order

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "gp_accession",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 11 },
  "literature_reference_pmid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "list_order",
  { data_type => "integer", is_nullable => 0 },
);

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

=head2 literature_reference_pmid

Type: belongs_to

Related object: L<GenomePropertiesDB::Result::LiteratureReference>

=cut

__PACKAGE__->belongs_to(
  "literature_reference_pmid",
  "GenomePropertiesDB::Result::LiteratureReference",
  { pmid => "literature_reference_pmid" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-07-20 12:10:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LASDcxeOd35gqNh2Hf+AFw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
