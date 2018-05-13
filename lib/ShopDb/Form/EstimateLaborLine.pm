package ShopDb::Form::EstimateLaborLine;

use HTML::FormHandler::Moose;
use Math::Round qw/nearest_ceil/;
use List::MoreUtils qw/uniq/;
extends 'ShopDb::Form::EstimateChargeLine';

has '+item_class' => ( default => 'EstimateLaborLines' );

sub options_category_value {
    my ($self, $field) = @_;
    my $category = $self->field('category')->get_default_value;
    my @values = $self->schema->resultset('EstimateLaborLines')->search({ category => $category }, { columns => [ 'category_value' ], distinct => 1 })->get_column('category_value')->all;
    my $default_values = {
        general => [ 'CAM Programming', 'Cleaning', 'Design', 'Drafting', 'Fixture Creation', 'Fixture Design', 'Leak Checking', 'Machine Operation', 'Machine Setup', 'Welding', 'Welding Fixture Design', 'Welding Fixture Machining' ],
        wire => [ 'Wire EDM' ],
    };
    die "Invalid category default $category" unless (exists $default_values->{$category});
    my @default_values = @{$default_values->{$category}};
    my $options = [ map { { value => $_, label => $_ } } sort &uniq (@default_values, @values) ];
    return $options;
}

has_field 'charge_hours' => (
    required => 1,
    required_message => 'You must specify the charge hours',
    fif_from_value => 1,
    apply => [
        { transform => sub { nearest_ceil(0.25, $_[0]) } },
    ],
);

has_field 'labor_rate' => (
    auth => 0,
);

no HTML::FormHandler::Moose;
1;
