#!/usr/bin/perl

#
# insurance_worksheet_graphs.pl
#
# Author: Michael J. Duff
# Last modified: December 18, 2010
#
# Description:
#

require "global.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "database_utilities.pl";

use DBI;


auth_user ($CLEARANCE_STAFF);

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
    my $grouping_field_sql = $grouping_field;

    my $sql;

    if ($group_field eq 'PAID_BY') {
	$sql = "SELECT SUM (IWE.PAID_BY_ATHLETE_PRIMARY) as YDATUM1, SUM (IWE.PAID_BY_ATHLETE_SECONDARY) as YDATUM2, SUM (IWE.INSURANCE_WRITEOFF) as YDATUM3, SUM (IWE.PAID_BY_MIAMI_PRIMARY) as YDATUM4, SUM (IWE.PAID_BY_MIAMI_SECONDARY) as YDATUM5";

    } else {
	$sql = "SELECT $grouping_field_sql as XDATUM, SUM (balance) as YDATUM";
    }


    $sql .= "
FROM   ATHLETE_LV as ALV, INSURANCE_WORKSHEETS IW, INSURANCE_WORKSHEET_ENTRIES IWE, INJURY_REPORT_LV IRLV

WHERE  ALV.ORIG_VERSION_ID = IW.ATHLETE_ID AND IW.WORKSHEET_ID = IWE.WORKSHEET_ID AND IW.INJURY_REPORT_ID = IRLV.ORIG_VERSION_ID
";

    if ($cgi_data->{'SEX'} && ($grouping_field ne "SEX")) {
	$sql .= " and ALV.SEX = '$cgi_data->{'SEX'}'";
    }

    if ($cgi_data->{'STATUS'}) {    # Not a possible grouping field
	$sql .= " and ALV.STATUS = '$cgi_data->{'STATUS'}'";
    }

    if ($cgi_data->{'SPORT'} && ($grouping_field ne "SPORT")) {
	$sql .= " and IRLV.SPORT = '$cgi_data->{'SPORT'}'";   # should use sport from the injury report? (doesn't match athlete sport in some cases)
    }
    
    if ($cgi_data->{'MEDICAL_PROVIDER'} && ($grouping_field ne "MEDICAL_PROVIDER")) {
	$sql .= " and IWE.MEDICAL_PROVIDER = '$cgi_data->{'MEDICAL_PROVIDER'}'";
    }

    if ($cgi_data->{'DATE_RECEIVED1'}) {
	$sql .= " and IWE.DATE_RECEIVED >= TO_DATE('$cgi_data->{'DATE_RECEIVED1'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'DATE_RECEIVED2'}) {
	$sql .= " and IWE.DATE_RECEIVED <= TO_DATE('$cgi_data->{'DATE_RECEIVED2'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'SERVICE_DATE1'}) {
	$sql .= " and IWE.SERVICE_DATE >= TO_DATE('$cgi_data->{'SERVICE_DATE1'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'SERVICE_DATE2'}) {
	$sql .= " and IWE.SERVICE_DATE <= TO_DATE('$cgi_data->{'SERVICE_DATE2'}', 'MM-DD-YYYY')";
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

    # Build up data to send to graphing function:
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

    # Display query criteria on graph results:
    my %paid_by_names = (
			 'paid_by_athlete_primary'   => 'Athlete Primary',
			 'paid_by_athlete_secondary' => 'Athlete Secondary',
			 'insurance_writeoff'        => 'Insurance Writeoff',
			 'paid_by_miami_primary'     => 'Maksim',
			 'paid_by_miami_secondary'   => 'Miami Athlete Insurance'
			 );

    my $sex                = ($cgi_data->{'SEX'}                && $grouping_field ne 'SEX'
			      ? $cgi_data->{'SEX'} : 'All');
    my $sport              = ($cgi_data->{'SPORT'}              && $grouping_field ne 'SPORT'
			      ? $cgi_data->{'SPORT'} : 'All');
    my $status             = ($cgi_data->{'STATUS'}
			      ? $cgi_data->{'STATUS'} : 'All');
    my $medical_provider   = ($cgi_data->{'MEDICAL_PROVIDER'}   && $grouping_field ne 'MEDICAL_PROVIDER'
			      ? $cgi_data->{'MEDICAL_PROVIDER'} : 'All');
    my $paid_by            = ($cgi_data->{'PAID_BY'}            && $grouping_field ne 'PAID_BY'
			      ? $paid_by_names{$cgi_data->{'PAID_BY'}} : 'All');
    my $date_received =
	($cgi_data->{'DATE_RECEIVED1'} ? $cgi_data->{'DATE_RECEIVED1'} : '') .   # beginning of date range
	' thru ' .
	($cgi_data->{'DATE_RECEIVED2'} ? $cgi_data->{'DATE_RECEIVED2'} : 'present');   # end of date range

    # Handle special case where neither end of date range is specified:
    if (! $cgi_data->{'DATE_RECEIVED1'} && ! $cgi_data->{'DATE_RECEIVED2'}) { $date_received = 'All time'; }


    my $service_date =
	($cgi_data->{'SERVICE_DATE1'} ? $cgi_data->{'SERVICE_DATE1'} : '') .   # beginning of date range
	' thru ' .
	($cgi_data->{'SERVICE_DATE2'} ? $cgi_data->{'SERVICE_DATE2'} : 'present');   # end of date range

    # Handle special case where neither end of date range is specified:
    if (! $cgi_data->{'SERVICE_DATE1'} && ! $cgi_data->{'SERVICE_DATE2'}) { $service_date = 'All time'; }


    print <<EOF;
<center>
<h1>Insurance Transactions vs. $grouping_field</h1>

<table border="1" cellpadding="5" cellspacing="0">
  <tr>
    <td align="left" valign="middle"><b>Sex:</b> $sex</td>
    <td align="left" valign="middle"><b>Sport:</b> $sport</td>
    <td align="left" valign="middle" colspan="2"><b>Athlete Status:</b> $status</td>
  </tr>
  <tr>
    <td align="left" valign="middle" colspan="2"><b>Medical Provider:</b> $medical_provider</td>
    <td align="left" valign="middle" colspan="2"><b>Paid By:</b> $paid_by</td>
  </tr>
  <tr>
    <td align="left" valign="middle" colspan="2"><b>Date Received:</b> $date_received</td>
    <td align="left" valign="middle" colspan="2"><b>Service Date:</b> $service_date</td>
  </tr>
</table>



<br><br>
<img src="/bin/graph.pl?GRAPH_TYPE=$graph_type&XDATA=$xdata&YDATA=$ydata" width=600 height=450>

<br>

<hr>

<b>$num_data Report(s) Found</b>
</center>
EOF
    ;
}

