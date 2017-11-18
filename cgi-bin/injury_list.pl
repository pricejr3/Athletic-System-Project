#!/usr/bin/perl

#
# injury_list
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: March 25, 1999
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
SELECT ORIG_VERSION_ID as ORIG_INJURY_REPORT_ID,
       TO_CHAR (DATE_REPORTED, 'MM-DD-YYYY') as DATE_REPORTED_CHAR,
       POSITION, BODY_PART, INJURY_TYPE, INJURY_STATUS
  from INJURY_REPORT_LV IRLV
WHERE
  ATHLETE_ID = '$orig_athlete_id'
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

<body bgcolor="#73b5ef">


<form method="POST" action="/bin/process_form" target="injury_body">

<input type="hidden" name="OPERATION" value="PREPARE_BLANK_FORM">
<input type="hidden" name="ORIG_ATHLETE_ID" value="$orig_athlete_id">

<p>Choose form: 
  <select name="FORM_NAME" size="1">
    <option value="INJURY_REPORT">Injury Report</option>
  </select>

<input type="submit" value=" Fill Out New Form ">

</form>
<hr>

<table border=0 width="100%">
<tr><td nowrap><b><u>Date Reported</u></b>
    <td nowrap><b><u>Position</u></b>
    <td nowrap><b><u>Body Part</u></b>
    <td nowrap><b><u>Injury Type</u></b>
    <td nowrap><b><u>Injury Status</u></b>
    <td nowrap><b><u>Insurance Worksheet</u></b>
</tr>
EOF
    ;


    my $num_rows = 0;
    my $db_data;
    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;
	$orig_injury_report_id = $db_data->{'orig_injury_report_id'};
	$date_reported_char = $db_data->{'date_reported_char'};
	$position_http = $position = $db_data->{'position'};  $position_http =~ s/ /+/g;
	$body_part_http = $body_part = $db_data->{'body_part'};  $body_part_http =~ s/ /+/g;
	$injury_type_http = $injury_type = $db_data->{'injury_type'};   $injury_type_http =~ s/ /+/g;
	$injury_status_http = $injury_status = $db_data->{'injury_status'};   $injury_status_http =~ s/ /+/g;

	print <<EOF;
<tr>
<td>
<a href="/bin/injury_details.pl?ORIG_ATHLETE_ID=$orig_athlete_id&ORIG_INJURY_REPORT_ID=$orig_injury_report_id&DATE_REPORTED_CHAR=$date_reported_char&POSITION=$position_http&BODY_PART=$body_part_http&INJURY_TYPE=$injury_type_http&INJURY_STATUS=$injury_status_http" target="_parent">$date_reported_char</a></td>

<td>$position</td>

<td>$body_part</td>

<td>$injury_type</td>

<td>$injury_status</td>

<td><a href="/bin/insurance_worksheet.pl?OPERATION=FRAMES&ORIG_ATHLETE_ID=$orig_athlete_id&ORIG_INJURY_REPORT_ID=$orig_injury_report_id" target="_parent">Worksheet</a></td>

EOF
    ;
    }


    $sth->finish;


    print <<EOF;
</table>

<hr>

<b>$num_rows Injury Record(s) Found</b>


<form method="POST" action="/bin/process_form" target="injury_body">

<input type="hidden" name="OPERATION" value="PREPARE_BLANK_FORM">
<input type="hidden" name="ORIG_ATHLETE_ID" value="$orig_athlete_id">

<p>Choose form: 
  <select name="FORM_NAME" size="1">
    <option value="INJURY_REPORT">Injury Report</option>
  </select>

<input type="submit" value=" Fill Out New Form ">

</form>

EOF
    ;
}
