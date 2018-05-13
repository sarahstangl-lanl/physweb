package ShopDb::Schema::Result::JobTotals;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::JobTotals

=cut

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');
__PACKAGE__->table("shopdb.job_totals");
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition("
SELECT
    SUM(`ll_total_projected_cost`) + SUM(`ml_total_projected_cost`) AS `total_projected_cost`,
    SUM(`ll_total_extended_cost`) + SUM(`ml_total_extended_cost`) AS `total_extended_cost`,
    SUM(`ll_total_projected_charge_hours`) AS `total_projected_charge_hours`,
    SUM(`ll_total_charge_hours`) AS `total_charge_hours`,
    SUM(`ll_total_projected_cost`) AS `ll_total_projected_cost`,
    SUM(`ll_total_extended_cost`) AS `ll_total_extended_cost`,
    SUM(`ml_total_projected_cost`) AS `ml_total_projected_cost`,
    SUM(`ml_total_extended_cost`) AS `ml_total_extended_cost`,
    `job_id`
FROM (
    SELECT
        IFNULL( `jobs`.`projected_charge_hours`, 0 ) AS `ll_total_projected_charge_hours`,
        IFNULL( `jobs`.`projected_labor_cost`, 0 ) AS `ll_total_projected_cost`,
        SUM( `machinist`.`labor_rate` * IFNULL( `ll`.`charge_hours`, 0 ) ) AS `ll_total_extended_cost`,
        SUM( IFNULL( `ll`.`charge_hours`, 0 ) ) AS `ll_total_charge_hours`,
        0 AS `ml_total_projected_cost`,
        0 AS `ml_total_extended_cost`,
        `jobs`.`job_id`
    FROM `shopdb`.`jobs` `jobs`
    LEFT JOIN `shopdb`.`labor_lines` `ll` ON `ll`.`job_id` = `jobs`.`job_id` AND `ll`.`active` = 1
    LEFT JOIN `shopdb`.`machinists` `machinist` ON `machinist`.`machinist_id` = `ll`.`machinist_id`
    GROUP BY `jobs`.`job_id`
    UNION SELECT
	0, 0, 0, 0,
        IFNULL( `jobs`.`projected_material_cost`, 0 ),
        SUM( IFNULL( `ml`.`quantity`, 0 ) * IFNULL( `ml`.`unit_cost`, 0 ) ),
        `jobs`.`job_id`
    FROM `shopdb`.`jobs` `jobs`
    LEFT JOIN `shopdb`.`material_lines` `ml` ON `ml`.`job_id` = `jobs`.`job_id` AND `ml`.`active` = 1
    GROUP BY `jobs`.`job_id`
    ) `job_totals`
GROUP BY job_id
");

=head1 ACCESSORS

=head2 job_id

=head2 total_charge_hours

=head2 total_extended_cost

=head2 ll_total_extended_cost

=head2 ml_total_extended_cost

=cut

__PACKAGE__->add_columns(
  'job_id',
  {
    data_type => 'integer',
    default_value => undef,
  },
  'total_charge_hours',
  {
    data_type => 'float',
    default_value => undef,
  },
  'total_extended_cost',
  {
    data_type => 'float',
    default_value => undef,
  },
  'll_total_extended_cost',
  {
    data_type => 'float',
    default_value => undef,
  },
  'ml_total_extended_cost',
  {
    data_type => 'float',
    default_value => undef,
  },
);

__PACKAGE__->inflate_column('total_charge_hours', { inflate => sub { return sprintf("%0.2f", shift); } });
__PACKAGE__->inflate_column('total_extended_cost', { inflate => sub { return sprintf("\$%0.2f", shift); } });
__PACKAGE__->inflate_column('ll_total_extended_cost', { inflate => sub { return sprintf("\$%0.2f", shift); } });
__PACKAGE__->inflate_column('ml_total_extended_cost', { inflate => sub { return sprintf("\$%0.2f", shift); } });

__PACKAGE__->set_primary_key('job_id');

1;
