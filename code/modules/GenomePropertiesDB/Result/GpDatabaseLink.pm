use utf8;
package GenomePropertiesDB::Result::GpDatabaseLink;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GenomePropertiesDB::Result::GpDatabaseLink

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<gp_database_link>

=cut

__PACKAGE__->table("gp_database_link");

=head1 ACCESSORS

=head2 gp_accession

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 11

=head2 db_id

  data_type: 'tinytext'
  is_nullable: 0

=head2 db_link

  data_type: 'tinytext'
  is_nullable: 0

=head2 other_params

  data_type: 'tinytext'
  is_nullable: 1

=head2 comment

  data_type: 'tinytext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "gp_accession",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 11 },
  "db_id",
  { data_type => "tinytext", is_nullable => 0 },
  "db_link",
  { data_type => "tinytext", is_nullable => 0 },
  "other_params",
  { data_type => "tinytext", is_nullable => 1 },
  "comment",
  { data_type => "tinytext", is_nullable => 1 },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-07-20 12:10:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xN9YdJaF5o0I4hqef+KO/g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
