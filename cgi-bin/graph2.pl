#!/usr/bin/perl

#
# graph
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: January 9, 2011
#
# Description:
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";


auth_user ($CLEARANCE_STUDENT);

$cgi_data = parse_cgi_data();

$graph_type = $cgi_data->{'GRAPH_TYPE'};
@xdata = split (/,/, $cgi_data->{'XDATA'});
@ydata = split (/,/, $cgi_data->{'YDATA'});

print "Content-type: image/gif\n";
print "Date: Thu, 03 Aug 1995 00:00:00 GMT\n";          # change?
print "Expires: Thu, 03 Aug 1995 00:00:00 GMT\n\n";     # change?


if ($graph_type eq "PIE") {
    use GD::Graph::pie;
    $graph = GD::Graph::pie->new (600, 450);

    @dclrs = qw(red lgreen lblue lyellow lpurple cyan lorange
		pink marine lbrown lred lgray orange blue gold
		yellow green purple dpink gray);

    $graph->set (
		 title        => '',
		 x_label      => '',
		 y_label      => '',
		 axislabelclr => 'black',
		 pie_height   => 30,
		 start_angle  => 235,
		 dclrs        => [ @dclrs ],
		 transparent  => 1
		 );

} elsif ($graph_type eq "LINE") {
    use GD::Graph::lines;
    $graph = GD::Graph::lines->new (600, 450);

    $graph->set (
    title         => '',
    x_label       => '',
    y_label       => '',
    line_types    => [1],
    line_width    => 2,
    dclrs         => ['red']
    );

} else {
    use GD::Graph::bars;
    $graph = GD::Graph::bars->new (600, 450);

    $graph->set (
		 title             => '',
		 x_label           => '',
		 x_labels_vertical => 1,
		 y_label           => '',
		 bar_spacing       => 8,
		 shadow_dpeth      => 4,
		 shadowclr         => 'dred',
		 transparent       => 1
		 );

}



@data = ([@xdata], [@ydata]);

print $graph->plot (\@data)->gif;

exit;
