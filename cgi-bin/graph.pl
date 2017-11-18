#!/usr/bin/perl

#
# graph
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: March 31, 1999
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
    use GIFgraph::pie;
    $graph = new GIFgraph::pie (600, 450);
    @dclrs = qw(red lgreen lblue lyellow lpurple cyan lorange
		pink marine lbrown lred lgray orange blue gold
		yellow green purple dpink gray);
    $graph->set (axislabelclr => 'black', pie_height => 30, dclrs => [ @dclrs ]);

} else {
    use GIFgraph::bars;
    $graph = new GIFgraph::bars (600, 450);
    $graph->set (x_labels_vertical => 1, bar_spacing => 5);
}


@data = ([@xdata], [@ydata]);

print $graph->plot (\@data);

exit;
