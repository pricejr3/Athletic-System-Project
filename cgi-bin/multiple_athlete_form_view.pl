#!/usr/bin/perl

# multiple_athlete_form_view.pl
#
# Copyright 2010, Michael Duff
# Author: Michael J. Duff
# Last modified: 11-Oct-2010
#
# Description: Enables the user to view and print forms across multiple athletes.
#

require "global.pl";
require "database_utilities.pl";
require "auth_user.pl";
require "parse.pl";
require "html_utilities.pl";
require "logging.pl";

use DBI;


($login_id, $clearance) = auth_user ($CLEARANCE_STAFF);

$cgi_data = parse_cgi_data();

search_athletes();

exit;



sub search_athletes
{
    prepare_cgi_data ($cgi_data);

    print_html_header ("Query results", $BASE_HREF);

    my $sql = build_sql_statement ($cgi_data);      # First build the SQL statement

    #print "SQL: $sql<br>\n";  # testing

    my $dbh = database_connect();                   # Establish connection to the database

    my $sth = execute_sql_statement ($dbh, $sql);   # Now execute the query

    if ($cgi_data->{'PRINT_VIEW'}) { print_view ($sth); }
    else                           { display_results ($sth); }  # Display the results

    database_disconnect ($dbh);                     # Disconnect from the database

    print_html_trailer();

    exit;
}



sub build_sql_statement
{
    my $cgi_data = shift;

    #
    # The "ORIG_VERSION_ID > 0" clause is there only to serve as a first clause
    #
    $sql = "
SELECT ATHLETE_ID, ORIG_VERSION_ID,
    LAST_NAME, FIRST_NAME, MIDDLE_NAME, SPORT, SEX
from athlete_lv where ATHLETE_ID > 0";


    if ($cgi_data->{'SPORT'}) {
	$sql .= " and SPORT = '$cgi_data->{'SPORT'}'";
    }

    if ($cgi_data->{'SEX'}) {
	$sql .= " and SEX = '$cgi_data->{'SEX'}'";
    }

    if ($cgi_data->{'STATUS'}) {
	$sql .= " and STATUS like '$cgi_data->{'STATUS'}%'";
    }

    $sql .= " order by UPPER (LAST_NAME)";

    $sql = format_sql_statement ($sql);

    return $sql;
}



sub display_results
{
    my $sth = shift;

    print <<EOF;

<h2 align="center">Matched Athletes</h2>

<form action="/bin/process_form" method="post">

<table border="1" width="100%" cellpadding="3" cellspacing="0">
<tr>
  <th>&nbsp;</th>
  <th align="left"><u>Athlete</u></th>
  <th><u>Sport</u></th>
  <th><u>Sex</u></th>
</tr>
EOF
    ;

    my $num_rows = 0;
    my $db_data;

    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;

	# Form field format: ORIG_ATHLETE_ID_{athlete ID #}_{sorting index #}

	print <<EOF;
<tr>
<td align="center"><input type="checkbox" name="ORIG_ATHLETE_ID_$db_data->{'orig_version_id'}_$num_rows" value="$db_data->{'orig_version_id'}" checked="checked"></td>
<td><a href="/bin/athlete_homepage.pl?ORIG_ATHLETE_ID=$db_data->{'orig_version_id'}" target="main">$db_data->{'last_name'}, $db_data->{'first_name'} $db_data->{'middle_name'}</a></td>
<td align="center">$db_data->{'sport'}</td>
<td align="center">$db_data->{'sex'}</td>
</tr>

EOF
    ;
    }


    $sth->finish;


    print <<EOF;
</table>

<hr>

<b>$num_rows Athlete(s) Found</b>

<input type="hidden" name="OPERATION" value="VIEW_FORM" />
<input type="hidden" name="VIEW_LATEST" value="1" />
<input type="hidden" name="BULK_VIEW" value="1" />

<table border="0" align="center">
  <tr>
    <td valign="middle"><b>Form Type:</b></td>
    <td valign="middle"><select name="FORM_NAME" size="1">
        <option value="ATHLETE_RELEASE">Athlete Release</option>
        <option value="FAMILY_HISTORY">Family History</option>
        <option value="FERPA_RELEASE">FERPA Release</option>
        <option value="HEALTH_APPRAISAL">Health Appraisal</option>
        <option value="HEALTH_HISTORY2">Health History</option>
        <option value="HEALTH_INFO_RELEASE">Health Information Release</option>
        <option value="INJURY_REPORT">Injury Report</option>
        <option value="INSURANCE">Insurance</option>
        <option value="MENTAL_HEALTH">Mental Health</option>
        <option value="PERSONAL_ADDTNL_INFO">Personal Additional Information</option>
        <option value="RECOMMENDED_TREATMENT">Recommended Treatment</option>
        <option value="TREATMENT_ADDTNL_INFO">Treatment Additional Information</option>
        <option value="TREATMENT_RECORD">Treatment Record</option>
        <option value="WAIVER">Waiver</option>
      </select></td>

   <td>
  <table border="0">
    <tr>
      <td valign="middle"><b>Form Date Between:</b></td>
      <td><input type="text" name="FORM_DATE1" size="10"><br>
<small>mm-dd-yyyy</small></td>
      <td align="center"><b>&nbsp; and</b> </td>
      <td align="center"><input type="text" name="FORM_DATE2" size="10"><br>
<small>mm-dd-yyyy</small></td>
    </tr>
  </table>
  </td>
  </tr>
</table>

<p align="center"><input type="submit" value=" Display Latest Form for Selected Athletes "></p>
<br>
</form>
EOF
}
