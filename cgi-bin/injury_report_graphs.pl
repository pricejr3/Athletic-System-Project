#!/usr/bin/perl

#
# graphical_injury_report_view
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: October 10, 2010
#
# Description:
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "database_utilities.pl";

use DBI;


auth_user ($CLEARANCE_STUDENT);

$cgi_data = parse_cgi_data();

prepare_cgi_data ($cgi_data);

print_html_header ("Query results", $BASE_HREF);

my $sql = build_sql_statement();                # First build the SQL statement

my $dbh = database_connect();                   # Establish connection to the database

my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

display_results ($sth);                         # Display the results

database_disconnect ($dbh);                     # Disconnect from the database

print_html_trailer();

exit;




sub build_sql_statement
{
    my $grouping_field = $cgi_data->{'GROUPING_FIELD'};
    my $grouping_field_sql;

    if ($grouping_field eq "SEX") {
	$grouping_field_sql = "ALV.SEX";
    } else {
	$grouping_field_sql = "IRLV." . $grouping_field;
    }


    my $sql = "
SELECT $grouping_field_sql as XDATUM, COUNT ($grouping_field_sql) as YDATUM

FROM   ATHLETE_LV as ALV, INJURY_REPORT_LV as IRLV

WHERE  ALV.ORIG_VERSION_ID = IRLV.ATHLETE_ID
";

    if ($cgi_data->{'SEX'} && ($grouping_field ne "SEX")) {
	$sql .= " and ALV.SEX = '$cgi_data->{'SEX'}'";
    }

    if ($cgi_data->{'STATUS'}) {    # Not a possible grouping field
	$sql .= " and ALV.STATUS = '$cgi_data->{'STATUS'}'";
    }

    if ($cgi_data->{'SPORT'} && ($grouping_field ne "SPORT")) {
	$sql .= " and IRLV.SPORT = '$cgi_data->{'SPORT'}'";
    }
    
    if ($cgi_data->{'POSITION'}) {  # Not a possible grouping field
	$sql .= " and IRLV.POSITION = '$cgi_data->{'POSITION'}'";
    }

    if ($cgi_data->{'BODY_PART'} && ($grouping_field ne "BODY_PART")) {
	$sql .= " and IRLV.BODY_PART = '$cgi_data->{'BODY_PART'}'";
    }

    if ($cgi_data->{'INJURY_TYPE'} && ($grouping_field ne "INJURY_TYPE")) {
	$sql .= " and IRLV.INJURY_TYPE = '$cgi_data->{'INJURY_TYPE'}'";
    }

    if ($cgi_data->{'INJURY_ENVIRONMENT'} && ($grouping_field ne "INJURY_ENVIRONMENT")) {
	$sql .= " and IRLV.INJURY_ENVIRONMENT like '$cgi_data->{'INJURY_ENVIRONMENT'}'";
    }

    if ($cgi_data->{'INJURY_COURSE'} && ($grouping_field ne "INJURY_COURSE")) {
	$sql .= " and IRLV.INJURY_COURSE = '$cgi_data->{'INJURY_COURSE'}'";
    }

    if ($cgi_data->{'INJURY_STATUS'} && ($grouping_field ne "INJURY_STATUS")) {
	$sql .= " and IRLV.INJURY_STATUS = '$cgi_data->{'INJURY_STATUS'}'";
    }

    if ($cgi_data->{'DATE_REPORTED1'} && ($grouping_field ne "DATE_REPORTED")) {
	$sql .= " and IRLV.DATE_REPORTED >= TO_DATE('$cgi_data->{'DATE_REPORTED1'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'DATE_REPORTED2'} && ($grouping_field ne "DATE_REPORTED")) {
	$sql .= " and IRLV.DATE_REPORTED <= TO_DATE('$cgi_data->{'DATE_REPORTED2'}', 'MM-DD-YYYY')";
    }

    $sql .= " GROUP BY $grouping_field_sql    ORDER BY $grouping_field_sql";


    $sql = format_sql_statement ($sql);

    # print "$sql <br>\n";
    

    return $sql;
}




sub display_results
{
    my $sth = shift;
    my $num_data = 0;

    my $grouping_field = $cgi_data->{'GROUPING_FIELD'};
    my $graph_type = $cgi_data->{'GRAPH_TYPE'};
    my (@xdata_list, @ydata_list, $xdata, $ydata);

    # Build up data to send to graphing function


    my $db_data;
    while ($db_data = $sth->fetchrow_hashref) {
	$num_data += $db_data->{'ydatum'};
	push (@xdata_list, $db_data->{'xdatum'} . ' (' . $db_data->{'ydatum'} . ')');
	push (@ydata_list, $db_data->{'ydatum'});
    }


    $sth->finish;

    $xdata = join (',', @xdata_list);   $xdata =~ s/ /+/g;  # HTTPize
    $ydata = join (',', @ydata_list);   $ydata =~ s/ /+/g;  # HTTPize

    my $title = $grouping_field;
    $title =~ s/_/ /g;

    # MJD (10/10/2010): Display query criteria on graph results:
    my $sex                = ($cgi_data->{'SEX'}                && $grouping_field ne 'SEX'
			      ? $cgi_data->{'SEX'} : 'All');
    my $sport              = ($cgi_data->{'SPORT'}              && $grouping_field ne 'SPORT'
			      ? $cgi_data->{'SPORT'} : 'All');
    my $status             = ($cgi_data->{'STATUS'}
			      ? $cgi_data->{'STATUS'} : 'All');
    my $position           = ($cgi_data->{'POSITION'}
			      ? $cgi_data->{'POSITION'} : 'All');
    my $body_part          = ($cgi_data->{'BODY_PART'}          && $grouping_field ne 'BODY_PART'
			      ? $cgi_data->{'BODY_PART'} : 'All');
    my $injury_type        = ($cgi_data->{'INJURY_TYPE'}        && $grouping_field ne 'INJURY_TYPE'
			      ? $cgi_data->{'INJURY_TYPE'} : 'All');
    my $injury_environment = ($cgi_data->{'INJURY_ENVIRONMENT'} && $grouping_field ne 'INJURY_ENVIRONMENT'
			      ? $cgi_data->{'INJURY_ENVIRONMENT'} : 'All');
    my $injury_status      = ($cgi_data->{'INJURY_STATUS'}
			      ? $cgi_data->{'INJURY_STATUS'} : 'All');
    my $injury_course      = ($cgi_data->{'INJURY_COURSE'}      && $grouping_field ne 'INJURY_COURSE'
			      ? $cgi_data->{'INJURY_COURSE'} : 'All');
    my $date_reported =
	($cgi_data->{'DATE_REPORTED1'} ? $cgi_data->{'DATE_REPORTED1'} : '') .   # beginning of date range
	' thru ' .
	($cgi_data->{'DATE_REPORTED2'} ? $cgi_data->{'DATE_REPORTED2'} : 'present');   # end of date range

    # Handle special case where neither end of date range is specified:
    if (! $cgi_data->{'DATE_REPORTED1'} && ! $cgi_data->{'DATE_REPORTED2'}) { $date_reported = 'All time'; }


    print <<EOF;
<center>
<h1>NUMBER OF INJURIES vs. $grouping_field</h1>

<table border="1" cellpadding="5" cellspacing="0">
  <tr>
    <td align="left" valign="middle"><b>Sex:</b> $sex</td>
    <td align="left" valign="middle"><b>Sport:</b> $sport</td>
    <td align="left" valign="middle" colspan="2"><b>Athlete Status:</b> $status</td>
  </tr>
  <tr>
    <td align="left" valign="middle"><b>Position:</b> $position</td>
    <td align="left" valign="middle"><b>Body Part:</b> $body_part</td>
    <td align="left" valign="middle"><b>Injury Type:</b> $injury_type</td>
    <td align="left" valign="middle"><b>Injury Environment:</b> $injury_environment</td>
  </tr>
  <tr>
    <td align="left" valign="middle" colspan="2"><b>Date Reported:</b> $date_reported</td>
    <td align="left" valign="middle"><b>Injury Course: </b>$injury_course</td>
    <td align="left" valign="middle"><b>Injury Status: </b>$injury_status</td>
  </tr>
</table>



<br><br>
<img src="/bin/graph2.pl?GRAPH_TYPE=$graph_type&XDATA=$xdata&YDATA=$ydata" width="600" height="450">

<br>

<hr>

<b>$num_data Report(s) Found</b>
</center>
EOF
    ;
}

