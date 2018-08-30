use utf8;
package GenomePropertiesDB::Result::LiteratureReference;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GenomePropertiesDB::Result::LiteratureReference

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<literature_reference>

=cut

__PACKAGE__->table("literature_reference");

=head1 ACCESSORS

=head2 pmid

  data_type: 'integer'
  is_nullable: 0

=head2 title

  data_type: 'mediumtext'
  is_nullable: 1

=head2 author

  data_type: 'mediumtext'
  is_nullable: 1

=head2 journal

  data_type: 'tinytext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pmid",
  { data_type => "integer", is_nullable => 0 },
  "title",
  { data_type => "mediumtext", is_nullable => 1 },
  "author",
  { data_type => "mediumtext", is_nullable => 1 },
  "journal",
  { data_type => "tinytext", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</pmid>

=back

=cut

__PACKAGE__->set_primary_key("pmid");

=head1 RELATIONS

=head2 gp_lit_refs

Type: has_many

Related object: L<GenomePropertiesDB::Result::GpLitRef>

=cut

__PACKAGE__->has_many(
  "gp_lit_refs",
  "GenomePropertiesDB::Result::GpLitRef",
  { "foreign.literature_reference_pmid" => "self.pmid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-07-08 14:51:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dI4yt8tu80XrqjX1iEftcA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
