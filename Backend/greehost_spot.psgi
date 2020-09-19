use strict;
use warnings;

use GreeHost::Spot;

my $app = GreeHost::Spot->apply_default_middlewares(GreeHost::Spot->psgi_app);
$app;

