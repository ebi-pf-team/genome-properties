use utf8;
package GenomePropertiesDB::Result::GoTerm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GenomePropertiesDB::Result::GoTerm

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<go_terms>

=cut

__PACKAGE__->table("go_terms");

=head1 ACCESSORS

=head2 go_id

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 term

  data_type: 'longtext'
  is_nullable: 0

=head2 category

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=cut

__PACKAGE__->add_columns(
  "go_id",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "term",
  { data_type => "longtext", is_nullable => 0 },
  "category",
  { data_type => "varchar", is_nullable => 0, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</go_id>

=back

=cut

__PACKAGE__->set_primary_key("go_id");

=head1 RELATIONS

=head2 gp_steps_to_go

Type: has_many

Related object: L<GenomePropertiesDB::Result::GpStepToGo>

=cut

__PACKAGE__->has_many(
  "gp_steps_to_go",
  "GenomePropertiesDB::Result::GpStepToGo",
  { "foreign.go_id" => "self.go_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ipr_steps_to_go

Type: has_many

Related object: L<GenomePropertiesDB::Result::IprStepToGo>

=cut

__PACKAGE__->has_many(
  "ipr_steps_to_go",
  "GenomePropertiesDB::Result::IprStepToGo",
  { "foreign.go_id" => "self.go_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-07-23 10:17:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4J/HJC00MJTIsXYOC4swPQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
