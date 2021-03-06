#!/usr/bin/perl

#
# injury_report_view
#
# Copyright 2000, Melampus Enterprises, Inc.
# Author: Michael J. Duff
# Last modified: August 7, 2000
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
    my $sql = "
SELECT ALV.ORIG_VERSION_ID as ORIG_ATHLETE_ID, IRLV.ORIG_VERSION_ID as ORIG_INJURY_REPORT_ID,
       ALV.LAST_NAME, ALV.FIRST_NAME, ALV.MIDDLE_NAME,
       IRLV.SPORT, IRLV.INJURY_ENVIRONMENT, IRLV.POSITION, IRLV.BODY_PART,
       IRLV.INJURY_TYPE, IRLV.INJURY_STATUS,
       TO_CHAR(IRLV.DATE_REPORTED, 'MM-DD-YYYY') as DATE_REPORTED_CHAR, IRLV.ATHLETICALLY_RELATED

FROM   ATHLETE_LV as ALV, INJURY_REPORT_LV as IRLV
WHERE  ALV.ORIG_VERSION_ID = IRLV.ATHLETE_ID
";

    if ($cgi_data->{'LAST_NAME'}) {
	$sql .= " and UPPER(ALV.LAST_NAME) like UPPER('$cgi_data->{'LAST_NAME'}%')";
    }

    if ($cgi_data->{'FIRST_NAME'}) {
	$sql .= " and UPPER(ALV.FIRST_NAME) like UPPER('$cgi_data->{'FIRST_NAME'}%')";
    }

    if ($cgi_data->{'MIDDLE_NAME'}) {
	$sql .= " and UPPER(ALV.MIDDLE_NAME) like UPPER('$cgi_data->{'MIDDLE_NAME'}%')";
    }

    if ($cgi_data->{'SEX'}) {
	$sql .= " and ALV.SEX = '$cgi_data->{'SEX'}'";
    }

    if ($cgi_data->{'STATUS'}) {
	$sql .= " and ALV.STATUS = '$cgi_data->{'STATUS'}'";
    }

    if ($cgi_data->{'SPORT'}) {
	$sql .= " and IRLV.SPORT = '$cgi_data->{'SPORT'}'";
    }

    if ($cgi_data->{'INJURY_ENVIRONMENT'}) {
	$sql .= " and IRLV.INJURY_ENVIRONMENT like '$cgi_data->{'INJURY_ENVIRONMENT'}'";
    }
    
    if ($cgi_data->{'POSITION'}) {
	$sql .= " and IRLV.POSITION = '$cgi_data->{'POSITION'}'";
    }

    if ($cgi_data->{'BODY_PART'}) {
	$sql .= " and IRLV.BODY_PART = '$cgi_data->{'BODY_PART'}'";
    }

    if ($cgi_data->{'INJURY_TYPE'}) {
	$sql .= " and IRLV.INJURY_TYPE = '$cgi_data->{'INJURY_TYPE'}'";
    }

    if ($cgi_data->{'INJURY_STATUS'}) {
	$sql .= " and IRLV.INJURY_STATUS = '$cgi_data->{'INJURY_STATUS'}'";
    }

    if ($cgi_data->{'DATE_REPORTED1'}) {
	$sql .= " and IRLV.DATE_REPORTED >= TO_DATE('$cgi_data->{'DATE_REPORTED1'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'DATE_REPORTED2'}) {
	$sql .= " and IRLV.DATE_REPORTED <= TO_DATE('$cgi_data->{'DATE_REPORTED2'}', 'MM-DD-YYYY')";
    }

    if ($cgi_data->{'ATHLETICALLY_RELATED'}) {
	$sql .= " and IRLV.ATHLETICALLY_RELATED = '$cgi_data->{'ATHLETICALLY_RELATED'}'";
    }

    $sql .= " ORDER BY IRLV.DATE_REPORTED DESC";


    $sql = format_sql_statement ($sql);

    #print "$sql <br>\n";

    return $sql;
}




sub display_results
{
    my $sth = shift;

    print <<EOF;
<table border=0 width="100%"><tr>
<td><b><u>Athlete</u></b></td>
<td><b><u>Sport</u></b></td>
<td><b><u>Environment</u></b></td>
<td><b><u>Athletically Related</u></b></td>
<td><b><u>Pos</u></b></td>
<td><b><u>Body Part</u></b></td>
<td><b><u>Injury Type</u></b></td>
<td><b><u>Date Reported</u></b></td>
<td><b><u>Injury Status</u></b></td>
<td><b><u>Insurance Worksheet</u></b></td>
</tr>
EOF
    ;

    
    my $num_rows = 0;

    my $db_data;
    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;

	$orig_athlete_id = $db_data->{'orig_athlete_id'};
	$orig_injury_report_id = $db_data->{'orig_injury_report_id'};

	print <<EOF;
<tr>
<td>
<a href="/bin/athlete_homepage.pl?ORIG_ATHLETE_ID=$orig_athlete_id" target="main">$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</a></td>

<td>$db_data->{'sport'}</td>

<td>$db_data->{'injury_environment'}</td>

<td>$db_data->{'athletically_related'}</td>

<td>$db_data->{'position'}</td>

<td>$db_data->{'body_part'}</td>

<td>$db_data->{'injury_type'}</td>

<td><a href="/bin/process_form?OPERATION=VIEW_FORM&VIEW_LATEST=1&FORM_NAME=INJURY_REPORT&ORIG_VERSION_ID=$orig_injury_report_id&ORIG_ATHLETE_ID=$orig_athlete_id" target="top">$db_data->{'date_reported_char'}</a></td>

<td>$db_data->{'injury_status'}</td>

<td><a href="/bin/insurance_worksheet.pl?ORIG_ATHLETE_ID=$orig_athlete_id&ORIG_INJURY_REPORT_ID=$orig_injury_report_id">Worksheet</a></td>

EOF
    ;

    }


    $sth->finish;

    print <<EOF;
</table>

<hr>

<b>$num_rows Report(s) Found</b>
EOF
    ;
}

