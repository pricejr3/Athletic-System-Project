#!/usr/bin/perl

#
# insurance_worksheet_list
#
# Copyright 2010
# Author: Michael J. Duff
# Last modified: November 14, 2010
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

$orig_athlete_id = $cgi_data->{'ORIG_ATHLETE_ID'};

print_http_header();

my $sql = build_sql_statement();                # First build the SQL statement

my $dbh = database_connect();                   # Establish connection to the database

my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

display_results ($sth);                         # Display the results

database_disconnect ($dbh);                     # Disconnect from the database

print_html_trailer();

exit;




sub build_sql_statement
{
    my $sql = "
SELECT IW.WORKSHEET_ID, IW.ATHLETE_ID as ATHLETE_ID, IW.INJURY_REPORT_ID as ORIG_INJURY_REPORT_ID,
       IW.TOTAL_BALANCE,
       TO_CHAR (IRLV.DATE_REPORTED, 'MM-DD-YYYY') as DATE_REPORTED_CHAR,
       IRLV.POSITION, IRLV.BODY_PART, IRLV.INJURY_TYPE, IRLV.INJURY_STATUS
  from INSURANCE_WORKSHEETS IW, INJURY_REPORT_LV IRLV
WHERE
  IW.INJURY_REPORT_ID = IRLV.ORIG_VERSION_ID and IW.ATHLETE_ID = $orig_athlete_id
order by DATE_REPORTED desc";

    $sql = format_sql_statement ($sql);

    return $sql;
}



sub display_results
{
    my $sth = shift;


    print <<EOF;
<html>
<head>
  <base href="$BASE_HREF">
  <link rel="stylesheet" type="text/css" href="/www/common.css"/>
</head>

<body bgcolor="#d0a0f0">

<h2 align="center">Insurance Worksheets</h2>

<table border=0 width="100%">
<tr><td nowrap><b><u>Injury Date Reported</u></b></td>
    <td nowrap><b><u>Position</u></b></td>
    <td nowrap><b><u>Body Part</u></b></td>
    <td nowrap><b><u>Injury Type</u></b></td>
    <td nowrap><b><u>Injury Status</u></b></td>
    <td nowrap align="right"><b><u>Balance</u></b></td>
</tr>
EOF
    ;


    my $num_rows = 0;
    my $db_data;
    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;

	$worksheet_id          = $db_data->{'worksheet_id'};
	$orig_injury_report_id = $db_data->{'injury_report_id'};
	$date_reported_char    = $db_data->{'date_reported_char'};
	$position              = $db_data->{'position'};
	$body_part             = $db_data->{'body_part'};
	$injury_type           = $db_data->{'injury_type'};
	$injury_status         = $db_data->{'injury_status'};
	$total_balance         = currency_format ($db_data->{'total_balance'}, 1);

	print <<EOF;
<tr>
<td><a href="/bin/insurance_worksheet.pl?WORKSHEET_ID=$worksheet_id" target="insurance_worksheet">$date_reported_char</a></td>

<td>$position</td>

<td>$body_part</td>

<td>$injury_type</td>

<td>$injury_status</td>

<td align="right">\$$total_balance</td>

</tr>
EOF
    ;
    }


    $sth->finish;


    print <<EOF;
</table>

<hr>

<b>$num_rows Insurance Worksheet(s) Found</b>

EOF
    ;
}



sub currency_format {
    my ($amount, $show_zero) = @_;
    if ($amount == 0 && ! $show_zero) { return ''; }
    else                              { return sprintf ("%.2f", $amount); }
}
