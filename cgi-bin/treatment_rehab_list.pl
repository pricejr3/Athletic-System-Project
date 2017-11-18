#!/usr/bin/perl

#
# treatment_rehab_list
#
# Copyright 2011, Michael Duff
# Author: Michael J. Duff
# Last modified: 28-May-2011
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
SELECT 'COACHES_REPORT' as FORM_NAME, 'Coaches Report' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR,
       INJURY as DESC1, '' as DESC2, '' as DESC3
  from COACHES_REPORT_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'RECOMMENDED_TREATMENT' as FORM_NAME, 'Recommended Treatment' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR,
       INJURY as DESC1, '' as DESC2, '' as DESC3
  from RECOMMENDED_TREATMENT_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'TREATMENT_ADDTNL_INFO' as FORM_NAME, 'Treatment Addtnl Info' as FORM_TYPE,
       ORIG_VERSION_ID, FORM_DATE, TO_CHAR (FORM_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR,
       SUBJECT as DESC1, '' as DESC2, '' as DESC3
  from TREATMENT_ADDTNL_INFO_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'


UNION ALL


SELECT 'TREATMENT_RECORD' as FORM_NAME, 'Treatment Record' as FORM_TYPE,
       ORIG_VERSION_ID, TREATMENT_DATE as FORM_DATE,
       TO_CHAR (TREATMENT_DATE, 'MM-DD-YYYY') as FORM_DATE_CHAR,
       POSITION as DESC1, BODY_PART as DESC2, INJURY_TYPE as DESC3
  from TREATMENT_RECORD_LV
WHERE
  ATHLETE_ID = '$orig_athlete_id'

order by FORM_DATE desc
";

    $sql = format_sql_statement($sql);

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

<body bgcolor="#ffd46b">

<form method="POST" action="/bin/process_form" target="treatment_rehab_body">

<input type="hidden" name="OPERATION" value="PREPARE_BLANK_FORM">
<input type="hidden" name="ORIG_ATHLETE_ID" value="$orig_athlete_id">

<p>Choose form: 
  <select name="FORM_NAME" size="1">
    <option value="TREATMENT_ADDTNL_INFO">Additional Info</option>
    <option value="COACHES_REPORT">Coaches Report</option>
    <option value="RECOMMENDED_TREATMENT">Recommended Treatment</option>
    <option value="TREATMENT_RECORD" selected>Treatment Record</option>
  </select>

<input type="submit" value=" Fill Out New Form ">

</form>
<hr>

<table border=0 width="100%">
<tr><td><b><u>Date</u></b>    <td><b><u>Form Type</u></b>   <td><b><u>Description</u></b>
EOF
    ;

    my $num_rows = 0;
    my $db_data;

    while ($db_data = $sth->fetchrow_hashref) {
	$num_rows++;
	$form_name = $db_data->{'form_name'};
	$form_type = $db_data->{'form_type'};
	$orig_version_id = $db_data->{'orig_version_id'};

	$description = "";
	if ($db_data->{'desc1'}) { $description = $db_data->{'desc1'}; }
	if ($db_data->{'desc2'}) { $description .= ", $db_data->{'desc2'}"; }
	if ($db_data->{'desc3'}) { $description .= ", $db_data->{'desc3'}"; }
	$description = substr ($description, 0, 50);  # Description should be 50 characters max
	

	print <<EOF;

<tr>
<td>$db_data->{'form_date_char'}

<td>
<a href="/bin/process_form?OPERATION=VIEW_FORM&VIEW_LATEST=1&FORM_NAME=$form_name&ORIG_VERSION_ID=$orig_version_id&ORIG_ATHLETE_ID=$orig_athlete_id" target="treatment_rehab_body">$form_type</a>

<td>$description
EOF
    ;
    }


    $sth->finish;


print <<EOF;
</table>

<hr>

<b>$num_rows Treatment/Rehab Record(s) Found</b>


<form method="POST" action="/bin/process_form" target="treatment_rehab_body">

<input type="hidden" name="OPERATION" value="PREPARE_BLANK_FORM">
<input type="hidden" name="ORIG_ATHLETE_ID" value="$orig_athlete_id">

<p>Choose form: 
  <select name="FORM_NAME" size="1">
    <option value="TREATMENT_ADDTNL_INFO">Additional Info</option>
    <option value="COACHES_REPORT">Coaches Report</option>
    <option value="RECOMMENDED_TREATMENT">Recommended Treatment</option>
    <option value="TREATMENT_RECORD" selected>Treatment Record</option>
  </select>

<input type="submit" value=" Fill Out New Form ">

</form>


EOF
    ;
}
